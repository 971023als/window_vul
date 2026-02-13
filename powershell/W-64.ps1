# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Windows_Firewall_Check.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-64"
$riskLevel = "중"
$diagnosisItem = "윈도우 방화벽 설정"
$remedialAction = "모든 네트워크 프로필(도메인, 개인, 공용)에 대해 윈도우 방화벽을 '사용'으로 설정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 윈도우 방화벽 설정 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 모든 방화벽 프로필 상태 가져오기
    $fwProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
    
    $isVulnerable = $false
    $statusDetails = @()
    $disabledProfiles = @()

    if ($null -eq $fwProfiles) {
        # 구형 OS(2003 등)나 명령어가 지원되지 않는 경우 netsh 사용 시도
        $netshResult = netsh advfirewall show allprofiles | Select-String "State"
        foreach ($line in $netshResult) {
            if ($line -match "OFF") {
                $isVulnerable = $true
            }
            $statusDetails += $line.ToString().Trim()
        }
    } else {
        # 최신 OS용 (2012 이상)
        foreach ($profile in $fwProfiles) {
            $name = $profile.Name
            $enabled = $profile.Enabled

            if ($enabled -eq "False" -or $enabled -eq $false) {
                $isVulnerable = $true
                $disabledProfiles += $name
            }
            $statusDetails += "$name($($enabled))"
        }
    }

    # 4. 최종 결과 판정
    if ($isVulnerable) {
        $result = "취약"
        $statusMsg = "일부 방화벽 프로필이 비활성화되어 있습니다: " + ($disabledProfiles -join ", ")
        $color = "Red"
    } else {
        $result = "양호"
        $statusMsg = "모든 방화벽 프로필이 활성화되어 있습니다. (" + ($statusDetails -join ", ") + ")"
        $color = "Green"
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