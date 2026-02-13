# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "NTP_Sync_Settings_Check.csv"

# 2. 진단 정보 기본 설정
$category = "로그 관리"
$code = "W-41"
$riskLevel = "중"
$diagnosisItem = "NTP 및 시각 동기화 설정"
$remedialAction = "Windows 시간 서비스 활성화 및 신뢰할 수 있는 NTP 서버(또는 도메인 컨트롤러)와 동기화 설정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 시각 동기화 설정 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 3-1. W32Time 서비스 상태 확인
    $timeSvc = Get-Service -Name "W32Time" -ErrorAction SilentlyContinue
    
    # 3-2. 레지스트리 설정값 확인
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
    $syncType = (Get-ItemProperty -Path $regPath -Name "Type" -ErrorAction SilentlyContinue).Type
    $ntpServer = (Get-ItemProperty -Path $regPath -Name "NtpServer" -ErrorAction SilentlyContinue).NtpServer

    # 3-3. 동기화 소스 상세 정보 (w32tm 명령어 활용)
    $w32tmStatus = w32tm /query /status /errorsilently | Select-String "Source"
    
    $isVulnerable = $false
    $statusMsg = ""

    # 판정 로직
    if ($null -eq $timeSvc -or $timeSvc.Status -ne "Running") {
        $isVulnerable = $true
        $statusMsg = "Windows 시간 서비스(W32Time)가 구동 중이 아닙니다."
    } elseif ($syncType -eq "NoSync") {
        $isVulnerable = $true
        $statusMsg = "동기화 유형이 'NoSync'(설정 안 함)로 되어 있습니다."
    } elseif ($syncType -eq "NTP") {
        if ($ntpServer -match "time.windows.com" -and $ntpServer -match "0x9") {
            $statusMsg = "기본 NTP 서버(time.windows.com)를 사용 중입니다. ($ntpServer)"
            # 업무 환경에 따라 기본값 유지도 양호로 볼 수 있으나, 가급적 내부/승인된 서버 권장
            $result = "양호"
        } else {
            $statusMsg = "지정된 NTP 서버와 동기화 중입니다. ($ntpServer)"
            $result = "양호"
        }
    } elseif ($syncType -eq "Nt5DS") {
        $statusMsg = "도메인 환경(AD)에서 도메인 컨트롤러와 시각을 동기화 중입니다."
        $result = "양호"
    } else {
        $statusMsg = "동기화 설정: $syncType / 서버: $ntpServer"
        $result = "양호"
    }

    # 최종 결과 판정
    if ($isVulnerable) {
        $result = "취약"
        $color = "Red"
    } else {
        $color = "Green"
    }

} catch {
    $result = "오류"
    $statusMsg = "점검 중 에러 발생: $($_.Exception.Message)"
    $color = "Yellow"
}

# 4. 결과 객체 생성
$report = [PSCustomObject]@{
    "Category"       = $category
    "Code"           = $code
    "Risk Level"     = $riskLevel
    "Diagnosis Item" = $diagnosisItem
    "Result"         = $result
    "Current Status" = $statusMsg
    "Remedial Action"= $remedialAction
}

# 5. 콘솔 출력 및 CSV 저장
Write-Host "[결과] : $result" -ForegroundColor $color
Write-Host "[현황] : $statusMsg"
Write-Host "------------------------------------------------"

$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray