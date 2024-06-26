# JSON 데이터 초기화
$json = @{
    분류 = "서비스관리"
    코드 = "W-53"
    위험도 = "상"
    진단 항목 = "원격터미널 접속 타임아웃 설정"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "원격터미널 접속 타임아웃 설정"
}

# 관리자 권한 확인 및 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "$PSCommandPath", "-Verb", "RunAs"
    exit
}

# 환경 설정
chcp 437 | Out-Null
$Host.UI.RawUI.BackgroundColor = "DarkGreen"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

# 변수 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 디렉터리 생성 및 초기화
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory -Force | Out-Null

# RDP 세션 타임아웃 설정 검사
$rdpTcpSettings = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
if ($rdpTcpSettings.MaxIdleTime -eq 0) {
    $json.진단 결과 = "취약"
    $json.현황 += "RDP 세션 타임아웃이 설정되지 않았습니다. 이는 취약점이 될 수 있습니다."
} else {
    $json.현황 += "RDP 세션 타임아웃이 적절하게 구성되었습니다."
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-53.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# 결과 요약 및 저장
Get-Content "$resultDir\W-53_${computerName}_diagnostic_results.json" | Out-File "$resultDir\security_audit_summary.txt"

# 정리 작업
Remove-Item -Path "$rawDir\*" -Force

Write-Host "Script has completed. Results have been saved to $resultDir\security_audit_summary.txt."
