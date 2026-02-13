# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Guest_Account_Status_Check.csv"

# 2. 진단 정보 기본 설정
$category = "계정관리"
$code = "W-02"
$riskLevel = "상"
$diagnosisItem = "Guest 계정 비활성화"
$remedialAction = "Guest 계정 상태를 '사용 안 함'으로 설정 (secpol.msc)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] Guest 계정 비활성화 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직 (SID가 -501로 끝나는 계정 탐지)
try {
    # 빌트인 Guest 계정(RID 501) 정보 가져오기
    $guestUser = Get-CimInstance -ClassName Win32_UserAccount | Where-Object { $_.SID -like "*-501" }
    
    # Disabled 속성이 True면 비활성화 상태 (양호)
    # Disabled 속성이 False면 활성화 상태 (취약)
    if ($guestUser.Disabled -eq $false) {
        $result = "취약"
        $status = "Guest 계정이 현재 활성화(Enabled) 되어 있습니다."
        $color = "Red"
    } else {
        $result = "양호"
        $status = "Guest 계정이 비활성화(Disabled) 되어 있습니다."
        $color = "Green"
    }
} catch {
    $result = "오류"
    $status = "Guest 계정 정보를 가져오는 중 에러가 발생했습니다: $($_.Exception.Message)"
    $color = "Yellow"
}

# 4. 결과 객체 생성
$report = [PSCustomObject]@{
    "Category"       = $category
    "Code"           = $code
    "Risk Level"     = $riskLevel
    "Diagnosis Item" = $diagnosisItem
    "Result"         = $result
    "Current Status" = $status
    "Remedial Action"= $remedialAction
}

# 5. 콘솔 출력 및 CSV 저장 (W-01과 동일한 파일에 추가하거나 새 파일 생성)
Write-Host "[결과] : $result" -ForegroundColor $color
Write-Host "[현황] : $status"
Write-Host "------------------------------------------------"

# CSV 저장 (Append 모드로 기존 리포트에 추가)
$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray