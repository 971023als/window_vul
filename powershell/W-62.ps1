# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Startup_Program_Analysis.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-62"
$riskLevel = "중"
$diagnosisItem = "시작 프로그램 목록 분석"
$remedialAction = "불필요하거나 출처가 불분명한 시작 프로그램 삭제 및 비활성화 (Taskmgr 또는 레지스트리 정리)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 시작 프로그램 목록 분석 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 3-1. WMI/CIM을 사용하여 통합 시작 프로그램 목록 조회
    # Registry(Run, RunOnce) 및 시작 폴더 항목을 모두 포함함
    $startupCommands = Get-CimInstance -ClassName Win32_StartupCommand

    $startupList = @()
    foreach ($cmd in $startupCommands) {
        $startupList += "[명칭: $($cmd.Name) / 경로: $($cmd.Command) / 사용자: $($cmd.User)]"
    }

    # 4. 판정 로직
    # 시작 프로그램의 '불필요함'은 관리자의 판단이 필요하므로, 목록 존재 시 검토 대상으로 분류
    if ($startupList.Count -gt 0) {
        $result = "검토 필요"
        $statusMsg = "총 $($startupList.Count)개의 시작 프로그램이 등록되어 있습니다. 목록: " + ($startupList -join " | ")
        $color = "Yellow"
    } else {
        $result = "양호"
        $statusMsg = "등록된 시작 프로그램이 없습니다."
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