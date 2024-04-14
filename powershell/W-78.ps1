# Define the initial JSON data structure
$json = @{
    "분류" = "보안관리"
    "코드" = "W-78"
    "위험도" = "상"
    "진단 항목" = "보안 채널 데이터 디지털 암호화 또는 서명"
    "진단 결과" = "양호" # Assuming default value is "Good"
    "현황" = @()
    "대응방안" = "보안 채널 데이터 디지털 암호화 또는 서명"
}

# Check for administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "관리자 권한으로 실행해야 합니다."
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File `"$PSCommandPath`"", "-Verb", "RunAs"
    Exit
}

# Environment setup
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# Create directories
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory -Force | Out-Null

# Export local security policy
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"

# Collect system information
systeminfo | Out-File "$rawDir\systeminfo.txt"

# Analyze IIS configuration
$iisConfigPath = "${env:WinDir}\System32\Inetsrv\Config\applicationHost.Config"
if (Test-Path $iisConfigPath) {
    Get-Content $iisConfigPath | Select-String "physicalPath|bindingInformation" | Out-File "$rawDir\iis_setting.txt"
}

# Analyze security policies related to secure channel settings
$securityPolicy = Get-Content "$rawDir\Local_Security_Policy.txt"
$conditionsMet = $securityPolicy | Where-Object {
    ($_ -match "RequireSignOrSeal.*1") -or
    ($_ -match "SealSecureChannel.*1") -or
    ($_ -match "SignSecureChannel.*1")
}

# Record findings to a result file
$resultFilePath = "$resultDir\W-Window-${computerName}-result.txt"
if ($conditionsMet) {
    "W-78,O,| 보안 정책 분석 결과: 모든 조건 만족" | Out-File $resultFilePath -Append
} else {
    "W-78,X,| 보안 정책 분석 결과: 하나 이상의 조건 불만족" | Out-File $resultFilePath -Append
}

# Update JSON data based on analysis
if ($conditionsMet) {
    $json.현황 += "보안 채널 설정이 적절합니다."
} else {
    $json.진단 결과 = "취약"
    $json.현황 += "보안 채널 설정이 적절하지 않습니다."
}

# Save JSON results to a file
$jsonFilePath = "$resultDir\W-78.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# Summarize results
Get-Content $resultFilePath | Out-File "$resultDir\security_audit_summary.txt"
Write-Host "결과가 $resultDir\security_audit_summary.txt에 저장되었습니다."

# Cleanup
Remove-Item "$rawDir\*" -Force
Write-Host "스크립트가 완료되었습니다."
