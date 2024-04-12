# JSON 데이터 초기화
$json = @{
    분류 = "서비스관리"
    코드 = "W-44"
    위험도 = "상"
    진단 항목 = "터미널 서비스 암호화 수준 설정"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "터미널 서비스 암호화 수준 설정"
}

# 관리자 권한 요청
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process PowerShell -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", $PSCommandPath, "-Verb", "RunAs"
    exit
}

# 콘솔 환경 설정
chcp 437 | Out-Null
$host.UI.RawUI.BackgroundColor = "DarkGreen"
$host.UI.RawUI.ForegroundColor = "Green"
Clear-Host

Write-Host "------------------------------------------설정 시작---------------------------------------"
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 이전 디렉토리 삭제 및 새 디렉토리 생성
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# RDP 최소 암호화 수준 검사 시작
Write-Host "------------------------------------------W-44 RDP 최소 암호화 수준 검사 시작------------------------------------------"
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
$minEncryptionLevel = (Get-ItemProperty -Path $regPath -Name "MinEncryptionLevel").MinEncryptionLevel

if ($minEncryptionLevel -gt 1) {
    $json."진단 결과" = "양호"
    $json.현황 += "RDP 최소 암호화 수준이 적절히 설정되어 있습니다."
} else {
    $json."진단 결과" = "취약"
    $json.현황 += "RDP 최소 암호화 수준이 낮게 설정되어 있어 보안에 취약할 수 있습니다."
}
Write-Host "-------------------------------------------W-44 RDP 최소 암호화 수준 검사 종료------------------------------------------"

# JSON 데이터를 파일로 저장
$jsonPath = "$resultDir\W-44_${computerName}_diagnostic_results.json"
$json | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# 결과 요약
Write-Host "결과 요약이 $resultDir\security_audit_summary.txt에 저장되었습니다."
Get-Content "$resultDir\W-44_${computerName}_diagnostic_results.json" | Out-File "$resultDir\security_audit_summary.txt"

# 정리 작업
Write-Host "정리 작업을 수행합니다..."
Remove-Item "$rawDir\*" -Force

Write-Host "스크립트를 종료합니다."
