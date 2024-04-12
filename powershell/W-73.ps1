# Initialize the JSON object
$json = @{
    분류 = "보안관리"
    코드 = "W-73"
    위험도 = "상"
    진단 항목 = "사용자가 프린터 드라이버를 설치할 수 없게 함"
    진단 결과 = "양호"  # Assume the default value is "Good"
    현황 = @()
    대응방안 = "사용자가 프린터 드라이버를 설치할 수 없도록 설정 조정"
}

# Request administrator privileges
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Verb RunAs"
    Exit
}

# Setup the environment
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# Delete existing data and create directories
Remove-Item -Path $rawDir, $resultDir -Recurse -Force
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# Export local security policy
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"

# Verify printer driver installation permissions
$securityPolicy = Get-Content "$rawDir\Local_Security_Policy.txt"
$addPrinterDrivers = $securityPolicy | Where-Object { $_ -match "AddPrinterDrivers" }

if ($addPrinterDrivers -match "1") {
    $json.현황 += "프린터 드라이버 추가 권한이 적절하게 설정되어 있습니다."
} else {
    $json.진단 결과 = "취약"
    $json.현황 += "프린터 드라이버 추가 권한이 적절하지 않게 설정되어 있습니다."
}

# Save the JSON data to a file
$jsonPath = "$resultDir\W-73_${computerName}_diagnostic_results.json"
$json | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# Cleanup
Remove-Item "$rawDir\*" -Force

Write-Host "스크립트가 완료되었습니다."
