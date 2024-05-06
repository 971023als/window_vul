# JSON 데이터 초기화
$json = @{
    Category = "보안 관리"
    Code = "W-69"
    RiskLevel = "높음"
    DiagnosticItem = "자동 로그온 기능 제어"
    DiagnosticResult = "양호"  # 기본값으로 '양호' 가정
    Status = @()
    Countermeasure = "보안 강화를 위해 자동 로그온 기능을 비활성화"
}

# 관리자 권한 확인 및 요청
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 환경 설정 및 디렉토리 생성
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDir, $resultDir -Force | Out-Null

# 자동 로그온 설정 확인
$autoAdminLogon = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon").AutoAdminLogon

if ($autoAdminLogon -eq "1") {
    $json.DiagnosticResult = "취약"
    $json.Status += "AutoAdminLogon이 활성화되어 보안 위험을 초래합니다."
} else {
    $json.Status += "AutoAdminLogon이 비활성화되어 시스템 보안이 강화되었습니다."
}

# JSON 결과를 파일로 저장
$jsonFilePath = "$resultDir\W-69.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# 결과 요약 및 저장
Get-Content -Path "$resultDir\W-69_${computerName}_diagnostic_results.json" | Out-File -FilePath "$resultDir\security_audit_summary.txt"
Write-Host "$resultDir\security_audit_summary.txt 에 결과가 저장되었습니다."

# 정리 및 스크립트 완료 메시지
Remove-Item -Path "$rawDir\*" -Force
Write-Host "스크립트가 완료되었습니다."
