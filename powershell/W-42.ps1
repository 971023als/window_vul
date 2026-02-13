# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Event_Log_Settings_Check.csv"

# 2. 진단 정보 기본 설정
$category = "로그 관리"
$code = "W-42"
$riskLevel = "하"
$diagnosisItem = "이벤트 로그 관리 설정"
$remedialAction = "이벤트 로그 최대 크기를 10,240KB 이상으로 설정하고 보관 기간을 90일 이상으로 조정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 이벤트 로그 설정 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 점검 대상 로그 목록
    $logNames = @("Application", "Security", "System")
    $vulnerableLogs = @()
    $logDetails = @()

    foreach ($logName in $logNames) {
        # WMI/CIM을 사용하여 로그 파일 설정 정보 조회
        $logFile = Get-CimInstance -ClassName Win32_NTEventLogFile | Where-Object { $_.LogFileName -eq $logName }
        
        if ($null -ne $logFile) {
            $maxSizeKB = $logFile.MaxFileSize / 1KB
            $overWritePolicy = $logFile.OverwritePolicy
            $overWriteOutdated = $logFile.OverwriteOutdatedEvents # 덮어쓰기 전 유지 일수
            
            # 판정 기준: 크기 10,240KB 미만 이거나 정책이 부적절한 경우
            # 현대 운영체제는 주로 '필요 시 덮어쓰기(WhenNeeded)'를 사용하므로 크기 위주로 점검하되 지침 명시
            $isSizeBad = $maxSizeKB -lt 10240
            
            # 가이드라인의 '90일' 기준 확인 (OverwriteOutdated가 90 미만인 경우)
            $isPolicyBad = ($overWritePolicy -eq "Outdated") -and ($overWriteOutdated -lt 90)

            if ($isSizeBad -or $isPolicyBad) {
                $vulnerableLogs += "$logName(크기:$maxSizeKB KB, 정책:$overWritePolicy)"
            }
            $logDetails += "$logName(크기:$maxSizeKB KB)"
        }
    }

    # 4. 최종 결과 판정
    if ($vulnerableLogs.Count -gt 0) {
        $result = "취약"
        $statusMsg = "다음 로그의 설정이 기준에 미달합니다: " + ($vulnerableLogs -join ", ")
        $color = "Red"
    } else {
        $result = "양호"
        $statusMsg = "모든 주요 로그 설정이 기준(10MB 이상)을 충족합니다. 상세: " + ($logDetails -join " / ")
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