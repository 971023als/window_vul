# Define the initial JSON data structure
$json = @{
    "분류" = "보안관리"
    "코드" = "W-77"
    "위험도" = "상"
    "진단 항목" = "LAN Manager 인증 수준"
    "진단 결과" = "양호"  # Assume the default value is "Good"
    "현황" = @()
    "대응방안" = "LAN Manager 인증 수준 변경"
}

# Request administrator privileges if not already running as an administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Verb RunAs"
    exit
}

# Environment setup
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# Clear existing data and create directories for new data
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# Export local security policy to a text file
secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null

# Analyze the LAN Manager authentication level setting from the registry
$lanManKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$lanManagerAuthLevel = Get-ItemProperty -Path $lanManKey -Name "LmCompatibilityLevel" -ErrorAction SilentlyContinue

# Conditionally update the JSON object based on the LM authentication level
if ($lanManagerAuthLevel -and $lanManagerAuthLevel.LmCompatibilityLevel -ge 3) {
    $json.현황 += "LAN Manager 인증 수준이 보안에 적합하게 설정되어 있습니다."
} else {
    $json.진단 결과 = "취약"
    $json.현황 += "LAN Manager 인증 수준이 보안 기준에 미치지 못합니다."
}

# Convert the hashtable to a JSON object and save it to a file
$jsonFilePath = "$resultDir\W-77.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath

# Provide summary and cleanup
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"
Write-Host "스크립트가 완료되었습니다."

# Cleanup the raw directory
Remove-Item "$rawDir\*" -Recurse -Force
