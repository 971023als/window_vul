# Define the initial JSON structure
$json = @{
    분류 = "보안관리"
    코드 = "W-75"
    위험도 = "상"
    진단 항목 = "경고 메시지 설정"
    진단 결과 = "양호"  # Assuming default value is "Good"
    현황 = @()
    대응방안 = "경고 메시지 설정"
}

# Check for administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -Verb RunAs -ArgumentList "-File `"$PSCommandPath`"", "-ExecutionPolicy Bypass"
    exit
}

# Environment setup
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# Clear existing data and create directories
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# Export local security policy
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"

# Verify login legal notice settings
$LegalNoticeCaption = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon").LegalNoticeCaption
$LegalNoticeText = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon").LegalNoticeText

if ($LegalNoticeCaption -ne $null -or $LegalNoticeText -ne $null) {
    $json.진단 결과 = "취약"
    $json.현황 += "로그인 시 법적 고지가 설정되어 있습니다."
} else {
    $json.현황 += "로그인 시 법적 고지가 설정되지 않았습니다."
}

# Convert the JSON object to a JSON string and save to a file
$jsonPath = "$resultDir\W-75_${computerName}_diagnostic_results.json"
$json | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# Cleanup
Remove-Item "$rawDir\*" -Force

Write-Host "스크립트가 완료되었습니다."
