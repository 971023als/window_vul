# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "User_Home_Directory_Check.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-58"
$riskLevel = "중"
$diagnosisItem = "사용자별 홈 디렉터리 권한 설정"
$remedialAction = "개별 사용자 홈 디렉터리 보안 속성에서 'Everyone' 권한 제거"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 사용자 홈 디렉터리 권한 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 프로필 기본 경로 파악 (Windows 버전별 차이 대응)
    $profileBase = if (Test-Path "C:\Users") { "C:\Users" } else { "C:\Documents and Settings" }
    
    # 제외 대상 설정 (공용/기본 프로필)
    $excludeList = @("Public", "Default", "Default User", "All Users", "desktop.ini")
    
    $userDirs = Get-ChildItem -Path $profileBase -Directory -Force | Where-Object { $excludeList -notcontains $_.Name }
    
    $vulnerableDirs = @()
    $statusMsg = ""

    if ($null -eq $userDirs) {
        $result = "양호"
        $statusMsg = "점검할 일반 사용자 홈 디렉터리가 존재하지 않습니다."
        $color = "Green"
    } else {
        foreach ($dir in $userDirs) {
            $acl = Get-Acl -Path $dir.FullName
            
            # Everyone (SID: S-1-1-0) 권한 확인
            $everyoneAccess = $acl.Access | Where-Object { 
                $_.IdentityReference.Value -eq "Everyone" -or 
                $_.IdentityReference.Value -eq "S-1-1-0" -or
                $_.IdentityReference.Value -match "모든 사용자"
            }

            if ($everyoneAccess) {
                $vulnerableDirs += $dir.Name
            }
        }

        # 4. 판정 로직
        if ($vulnerableDirs.Count -gt 0) {
            $result = "취약"
            $statusMsg = "다음 사용자 디렉터리에 'Everyone' 권한이 존재합니다: " + ($vulnerableDirs -join ", ")
            $color = "Red"
        } else {
            $result = "양호"
            $statusMsg = "모든 사용자별 홈 디렉터리에서 'Everyone' 권한이 적절히 제한되어 있습니다."
            $color = "Green"
        }
    }
} catch {
    $result = "오류"
    $statusMsg = "점검 중 에러 발생: $($_.Exception.Message)"
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
    "Remedial Action"= $remedialAction
}

# 6. 콘솔 출력 및 CSV 저장
Write-Host "[결과] : $result" -ForegroundColor $color
Write-Host "[현황] : $statusMsg"
Write-Host "------------------------------------------------"

$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray