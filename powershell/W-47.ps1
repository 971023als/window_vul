# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "ScreenSaver_Settings_Check.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-47"
$riskLevel = "하"
$diagnosisItem = "화면 보호기 설정"
$remedialAction = "화면 보호기 활성화, 대기 시간 10분 이하, '다시 시작할 때 로그온 화면 표시' 체크"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 화면 보호기 설정 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 레지스트리 경로 (사용자 설정 및 그룹 정책)
    $regPath = "HKCU:\Control Panel\Desktop"
    $gpoPath = "HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop"

    # 값 가져오기 (Active, IsSecure, Timeout)
    $scrActive = (Get-ItemProperty -Path $regPath -Name "ScreenSaveActive" -ErrorAction SilentlyContinue).ScreenSaveActive
    $scrSecure = (Get-ItemProperty -Path $regPath -Name "ScreenSaverIsSecure" -ErrorAction SilentlyContinue).ScreenSaverIsSecure
    $scrTimeout = (Get-ItemProperty -Path $regPath -Name "ScreenSaveTimeOut" -ErrorAction SilentlyContinue).ScreenSaveTimeOut

    # GPO에서 설정된 경우 우선 확인
    if (Test-Path $gpoPath) {
        $gpoActive = (Get-ItemProperty -Path $gpoPath -Name "ScreenSaveActive" -ErrorAction SilentlyContinue).ScreenSaveActive
        $gpoSecure = (Get-ItemProperty -Path $gpoPath -Name "ScreenSaverIsSecure" -ErrorAction SilentlyContinue).ScreenSaverIsSecure
        $gpoTimeout = (Get-ItemProperty -Path $gpoPath -Name "ScreenSaveTimeOut" -ErrorAction SilentlyContinue).ScreenSaveTimeOut
        
        if ($null -ne $gpoActive) { $scrActive = $gpoActive }
        if ($null -ne $gpoSecure) { $scrSecure = $gpoSecure }
        if ($null -ne $gpoTimeout) { $scrTimeout = $gpoTimeout }
    }

    $isVulnerable = $false
    $statusMsg = ""

    # 판정 로직
    # 1. 활성화 여부 (1: Active, 0: Inactive)
    if ($scrActive -ne "1") {
        $isVulnerable = $true
        $statusMsg = "화면 보호기가 설정되어 있지 않습니다."
    } else {
        # 2. 암호 보호 여부 (1: Secure, 0: Not Secure)
        if ($scrSecure -ne "1") {
            $isVulnerable = $true
            $statusMsg = "화면 보호기 해제 시 암호(로그온 화면)를 사용하지 않습니다."
        }
        
        # 3. 대기 시간 확인 (10분 = 600초)
        $timeoutMin = [math]::Round($scrTimeout / 60)
        if ($scrTimeout -gt 600 -or $null -eq $scrTimeout) {
            $isVulnerable = $true
            $statusMsg += " 대기 시간이 10분을 초과하거나 설정되지 않았습니다. (현재: $timeoutMin 분)"
        }
    }

    # 최종 결과 판정
    if ($isVulnerable) {
        $result = "취약"
        $color = "Red"
    } else {
        $result = "양호"
        $statusMsg = "화면 보호기가 활성화되어 있으며(암호 보호 포함), 대기 시간($timeoutMin 분)이 적절합니다."
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