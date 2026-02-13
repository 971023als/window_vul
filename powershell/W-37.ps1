# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Scheduled_Tasks_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-37"
$riskLevel = "중"
$diagnosisItem = "예약된 작업에 의심스러운 명령 점검"
$remedialAction = "작업 스케줄러(taskschd.msc)에서 비인가된 작업 및 의심스러운 실행 파일 제거"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 예약된 작업 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 모든 예약된 작업 가져오기
    $allTasks = Get-ScheduledTask
    
    $suspiciousTasks = @()
    $manualCheckTasks = @()

    foreach ($task in $allTasks) {
        $taskName = $task.TaskName
        $taskPath = $task.TaskPath
        $actions = $task.Actions
        
        # 실행 파일 및 인자값 추출
        $execCmd = ""
        foreach ($action in $actions) {
            if ($action.Execute) { $execCmd += $action.Execute + " " + $action.Arguments }
            if ($action.ComHandler) { $execCmd += "[COM] " + $action.ComHandler.ClassId }
        }

        # 의심스러운 패턴 정의 (PowerShell 인코딩, 임시 폴더 실행, 네트워크 도구 등)
        $suspiciousPattern = "powershell|cmd.exe|bitsadmin|certutil|ftp|temp|appdata|base64|download|http"

        # 판정 로직
        # 1. 마이크로소프트 기본 경로(\Microsoft\...)가 아닌 경우 수동 확인 대상으로 분류
        if ($taskPath -notmatch "^\\Microsoft") {
            # 2. 그 중에서도 의심스러운 명령 패턴이 있는 경우 '취약(의심)'으로 분류
            if ($execCmd -match $suspiciousPattern) {
                $suspiciousTasks += [PSCustomObject]@{
                    Name = $taskName
                    Path = $taskPath
                    Command = $execCmd
                    Status = $task.State
                    Type = "의심(Suspicious)"
                }
            } else {
                $manualCheckTasks += [PSCustomObject]@{
                    Name = $taskName
                    Path = $taskPath
                    Command = $execCmd
                    Status = $task.State
                    Type = "확인필요(User-Defined)"
                }
            }
        }
    }

    # 4. 최종 결과 판정
    if ($suspiciousTasks.Count -gt 0) {
        $result = "취약"
        $statusMsg = "의심스러운 명령이 포함된 예약 작업이 발견되었습니다: " + ($suspiciousTasks.Name -join ", ")
        $color = "Red"
    } elseif ($manualCheckTasks.Count -gt 0) {
        $result = "수동 확인"
        $statusMsg = "사용자 정의 예약 작업이 존재합니다. 직접 검토가 필요합니다: " + ($manualCheckTasks.Name -join ", ")
        $color = "Yellow"
    } else {
        $result = "양호"
        $statusMsg = "의심스러운 예약 작업이 발견되지 않았습니다."
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

# 상세 리스트를 별도 로그용으로 추가 저장 가능 (여기서는 통합 리포트용)
$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray