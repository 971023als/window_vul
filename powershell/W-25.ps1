# Initialize diagnostics JSON object
$json = @{
    분류 = "계정관리"
    코드 = "W-25"
    위험도 = "상"
    진단 항목 = "Use of decryptable encryption to store passwords"
    진단 결과 = "양호" # Assuming 'Good' as the default
    현황 = @()
    대응방안 = "Use decryptable encryption to store passwords"
}

# Request Administrator privileges
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "`"$PSCommandPath`"", "-Verb", "RunAs"
    Exit
}

# Environment and initial setup
chcp 437 | Out-Null
$host.UI.RawUI.ForegroundColor = "Green"
$computerName = $env:COMPUTERNAME
$directories = @("C:\Window_$($computerName)_raw", "C:\Window_$($computerName)_result")

# Directory setup
foreach ($dir in $directories) {
    If (Test-Path $dir) { Remove-Item -Path $dir -Recurse -Force }
    New-Item -Path $dir -ItemType Directory | Out-Null
}

# System information and security policy export
secedit /export /cfg "$($directories[0])\Local_Security_Policy.txt"
(Get-Location).Path | Out-File "$($directories[0])\install_path.txt"
systeminfo | Out-File "$($directories[0])\systeminfo.txt"

# Analyze IIS configuration for "Enable Parent Paths" setting
$applicationHostConfigPath = "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig = Get-Content $applicationHostConfigPath
$applicationHostConfig | Out-File "$($directories[0])\iis_setting.txt"
$enableParentPaths = $applicationHostConfig | Select-String -Pattern "asp enableParentPaths"

# Diagnostic result based on the setting
If (Get-Service W3SVC -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' } -and $enableParentPaths) {
    $json.진단 결과 = "취약"
    $json.현황 += "부모 경로 사용 설정이 활성화되어 있어 보안 위반."
} Else {
    $json.진단 결과 = "양호"
    $json.현황 += If ($enableParentPaths) { "부모 경로 사용 설정이 활성화되어 있으나, IIS 서비스 비활성화 상태." } Else { "부모 경로 사용 설정이 비활성화되어 있어 보안 준수." }
}

# Save the diagnostic results to a file and capture configuration data
$json | ConvertTo-Json -Depth 3 | Out-File "$($directories[1])\W-Window-$($computerName)-diagnostic_result.json"
$applicationHostConfig | Select-String -Pattern "enableParentPaths" | Out-File "$($directories[1])\W-Window-$($computerName)-rawdata.txt" -Append
