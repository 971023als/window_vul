# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "SAM_File_Access_Control_Check.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-46"
$riskLevel = "상"
$diagnosisItem = "SAM 파일 접근 통제 설정"
$remedialAction = "SAM 파일 권한에서 'Administrators' 및 'SYSTEM'을 제외한 모든 계정/그룹 제거"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] SAM 파일 접근 통제 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # SAM 파일 경로 설정
    $samPath = "$env:SystemRoot\System32\config\SAM"
    
    if (-not (Test-Path $samPath)) {
        $result = "오류"
        $statusMsg = "SAM 파일을 찾을 수 없습니다. 경로 확인이 필요합니다."
        $color = "Yellow"
    } else {
        # ACL(접근 제어 목록) 가져오기
        $acl = Get-Acl -Path $samPath
        $isVulnerable = $false
        $unauthorizedAccess = @()

        # 허용된 SID 정의 (언어 중립적 점검을 위해 SID 사용)
        # S-1-5-18: SYSTEM
        # S-1-5-32-544: Built-in Administrators
        $allowedSIDs = @("S-1-5-18", "S-1-5-32-544")

        foreach ($access in $acl.Access) {
            $sid = $access.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).Value
            
            # 허용된 SID 목록에 없는 계정이 권한을 가지고 있는지 확인
            if ($sid -notin $allowedSIDs) {
                $isVulnerable = $true
                $unauthorizedAccess += "$($access.IdentityReference)($sid)"
            }
        }

        # 4. 판정 로직
        if ($isVulnerable) {
            $result = "취약"
            $statusMsg = "허용되지 않은 계정/그룹이 SAM 파일에 접근 권한을 가지고 있습니다: " + ($unauthorizedAccess -join ", ")
            $color = "Red"
        } else {
            $result = "양호"
            $statusMsg = "Administrators 및 SYSTEM 그룹만 SAM 파일에 접근할 수 있도록 적절히 제한되어 있습니다."
            $color = "Green"
        }
    }
} catch {
    $result = "오류"
    $statusMsg = "권한 부족 또는 파일 잠금으로 인해 SAM 파일 ACL을 읽을 수 없습니다. (관리자 권한 실행 필수)"
    $color = "Yellow"
}

# 5. 결과 객체 생성
$report = [PSCustomObject]@{
    "Category"       = $category
    "Code"           = $code
    "Risk Level"     = $riskLevel
    "Diagnosis Item" = $diagnosisItem
    "Result"         = $result
    "Current Status" = $statusMsg
    "RemedialAction" = $remedialAction
}

# 6. 콘솔 출력 및 CSV 저장
Write-Host "[결과] : $result" -ForegroundColor $color
Write-Host "[현황] : $statusMsg"
Write-Host "------------------------------------------------"

$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray