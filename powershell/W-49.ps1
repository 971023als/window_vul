# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Remote_Shutdown_Right_Check.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-49"
$riskLevel = "상"
$diagnosisItem = "원격 시스템에서 강제로 시스템 종료"
$remedialAction = "로컬 보안 정책에서 '원격 시스템에서 강제로 시스템 종료' 권한에 Administrators 외의 계정 제거"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 원격 시스템 종료 권한 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 3-1. 로컬 보안 정책(사용자 권한 할당) 내보내기
    $tempFile = [System.IO.Path]::GetTempFileName()
    secedit /export /cfg $tempFile /areas USER_RIGHTS | Out-Null
    
    # 내보낸 파일 읽기 (유니코드 인코딩 처리)
    $policyContent = Get-Content $tempFile -Encoding Unicode
    
    # 3-2. 'SeRemoteShutdownPrivilege' 항목 찾기
    $remoteShutdownRight = $policyContent | Where-Object { $_ -match "SeRemoteShutdownPrivilege" }
    
    $isVulnerable = $false
    $statusMsg = ""
    $currentRights = ""

    if ($null -eq $remoteShutdownRight) {
        # 설정이 비어있는 경우 (기본적으로 안전한 상태로 간주 가능)
        $result = "양호"
        $statusMsg = "원격 시스템 종료 권한이 어떤 계정에도 부여되지 않았습니다."
        $color = "Green"
    } else {
        # 값 파싱 (예: SeRemoteShutdownPrivilege = *S-1-5-32-544)
        $currentRights = $remoteShutdownRight.Split('=')[1].Trim().Replace("*", "")
        $rightsArray = $currentRights.Split(',')

        # 허용된 SID: S-1-5-32-544 (Built-in Administrators)
        $allowedSID = "S-1-5-32-544"
        $unauthorizedUsers = @()

        foreach ($sid in $rightsArray) {
            $sid = $sid.Trim()
            if ($sid -ne $allowedSID -and $sid -ne "") {
                $isVulnerable = $true
                try {
                    # SID를 이름으로 변환 시도
                    $objSID = New-Object System.Security.Principal.SecurityIdentifier($sid)
                    $objUser = $objSID.Translate([System.Security.Principal.NTAccount])
                    $unauthorizedUsers += $objUser.Value
                } catch {
                    $unauthorizedUsers += $sid
                }
            }
        }

        # 4. 판정 로직
        if ($isVulnerable) {
            $result = "취약"
            $statusMsg = "Administrators 외 권한을 가진 계정/그룹이 존재합니다: " + ($unauthorizedUsers -join ", ")
            $color = "Red"
        } else {
            $result = "양호"
            $statusMsg = "Administrators 그룹만 원격 시스템 종료 권한을 가지고 있습니다."
            $color = "Green"
        }
    }
} catch {
    $result = "오류"
    $statusMsg = "점검 중 에러 발생: $($_.Exception.Message)"
    $color = "Yellow"
} finally {
    # 임시 파일 삭제
    if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
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