# JSON 데이터 초기화
$json = @{
    분류 = "패치관리"
    코드 = "W-54"
    위험도 = "상"
    진단 항목 = "예약된 작업에 의심스러운 명령이 등록되어 있는지 점검"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "예약된 작업에 의심스러운 명령이 등록되어 있는지 점검"
}

# 관리자 권한 확인 및 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "$PSCommandPath", "-Verb", "RunAs"
    exit
}

# 환경 설정
$Host.UI.RawUI.BackgroundColor = "DarkGreen"
$Host.UI.RawUI.ForegroundColor = "White"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# 변수 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 디렉터리 생성 및 초기화
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory -Force | Out-Null

# 스케줄러 작업 검사
$schedulerTasks = schtasks /query /fo CSV | ConvertFrom-Csv
If ($schedulerTasks) {
    $suspiciousTasks = $schedulerTasks | Where-Object { $_.TaskName -like "*admin*" -or $_.TaskName -like "*hack*" }
    If ($suspiciousTasks) {
        $json.진단 결과 = "경고"
        $json.현황 += "의심스러운 스케줄러 작업이 발견되었습니다: $($suspiciousTasks.TaskName)"
    } Else {
        $json.현황 += "의심스러운 스케줄러 작업이 없으며, 시스템은 안전합니다."
    }
} Else {
    $json.현황 += "스케줄러에 예약된 작업이 없으며, 이는 보안 상태가 안전함을 나타냅니다."
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-54.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# 결과 요약 및 저장
Get-Content "$jsonFilePath" | Out-File "$resultDir\security_audit_summary.txt"

# 정리 작업
Remove-Item "$rawDir\*" -Force

Write-Host "Script has completed. Results have been saved to $resultDir\security_audit_summary.txt."
