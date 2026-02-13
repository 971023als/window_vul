# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Admin_Account_Name_Check.csv"

# 2. 진단 정보 기본 설정
$category = "계정관리"
$code = "W-01"
$riskLevel = "상"
$diagnosisItem = "Administrator 계정 이름 바꾸기"
$remedialAction = "Administrator 계정 이름 변경 (secpol.msc)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 관리자 계정 이름 변경 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직 (SID가 -500으로 끝나는 계정 탐지)
try {
    # 빌트인 관리자 계정(RID 500) 정보 가져오기
    $adminUser = Get-CimInstance -ClassName Win32_UserAccount | Where-Object { $_.SID -like "*-500" }
    $currentName = $adminUser.Name

    if ($currentName -ieq "Administrator") {
        $result = "취약"
        $status = "관리자 계정의 기본 이름(Administrator)이 변경되지 않았습니다."
        $color = "Red"
    } else {
        $result = "양호"
        $status = "관리자 계정 이름이 [$currentName](으)로 변경되어 있습니다."
        $color = "Green"
    }
} catch {
    $result = "오류"
    $status = "계정 정보를 가져오는 중 에러가 발생했습니다: $($_.Exception.Message)"
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

# 5. 콘솔 출력 및 CSV 저장
Write-Host "[결과] : $result" -ForegroundColor $color
Write-Host "[현황] : $status"
Write-Host "------------------------------------------------"

# CSV 저장 (UTF8 적용으로 한글 깨짐 방지)
$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray