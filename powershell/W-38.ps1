# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Security_Patch_Management_Check.csv"

# 2. 진단 정보 기본 설정
$category = "패치 관리"
$code = "W-38"
$riskLevel = "상"
$diagnosisItem = "주기적 보안 패치 및 벤더 권고사항 적용"
$remedialAction = "Windows 업데이트 서비스 활성화 및 보안 패치 관리 절차 수립 (최소 월 1회 권장)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 보안 패치 관리 상태 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 3-1. Windows Update 서비스(wuauserv) 상태 확인
    $updateSvc = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
    $isSvcRunning = $false
    $svcStatusMsg = "Update 서비스 없음"

    if ($null -ne $updateSvc) {
        $startType = (Get-CimInstance Win32_Service -Filter "Name='wuauserv'").StartMode
        $svcStatusMsg = "상태($($updateSvc.Status))/시작유형($startType)"
        if ($updateSvc.Status -eq "Running" -or $startType -ne "Disabled") {
            $isSvcRunning = $true
        }
    }

    # 3-2. 최근 설치된 보안 패치(Hotfix) 이력 확인
    # 'Security Update' 카테고리의 패치 중 가장 최근 날짜 확인
    $recentHotfix = Get-HotFix | Where-Object { $_.Description -match "Security|Update" } | Sort-Object InstalledOn -Descending | Select-Object -First 1
    
    $isRecentlyPatched = $false
    $patchStatusMsg = ""

    if ($null -eq $recentHotfix) {
        $patchStatusMsg = "설치된 보안 패치 이력이 없습니다."
    } else {
        $lastDate = $recentHotfix.InstalledOn
        $daysSince = ((Get-Date) - $lastDate).Days
        
        # 가이드라인 기준: 최근 30일 이내 패치 권장 (환경에 따라 90일로 조정 가능)
        if ($daysSince -le 30) {
            $isRecentlyPatched = $true
            $patchStatusMsg = "최근 패치일: $lastDate ($daysSince 일 전, 양호)"
        } else {
            $patchStatusMsg = "최근 패치일: $lastDate ($daysSince 일 전, 지연됨)"
        }
    }

    # 4. 판정 로직
    if ($isSvcRunning -and $isRecentlyPatched) {
        $result = "양호"
        $statusMsg = "패치 서비스가 활성화되어 있으며, 주기적인 업데이트가 이루어지고 있습니다. ($patchStatusMsg)"
        $color = "Green"
    } elseif ($isSvcRunning -and -not $isRecentlyPatched) {
        $result = "취약"
        $statusMsg = "패치 서비스는 활성화되어 있으나, 장기간 업데이트가 누락되었습니다. ($patchStatusMsg)"
        $color = "Red"
    } else {
        $result = "취약"
        $statusMsg = "패치 서비스가 비활성화되어 있거나 패치 이력이 관리되지 않고 있습니다. ($svcStatusMsg)"
        $color = "Red"
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