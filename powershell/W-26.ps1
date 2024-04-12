$json = @{
    Classification = "Account Management"
    Code = "W-26"
    Risk = "High"
    Diagnosis = "Use of decryptable encryption for password storage"
    Result = "Good"  # Assuming 'Good' as the default
    Status = @()
    Recommendation = "Use decryptable encryption for password storage"
}

# Request Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File `"$PSCommandPath`"", "-Verb RunAs"
    exit
}

# Environment setup
$computerName = $env:COMPUTERNAME
$directories = @("C:\Window_${computerName}_raw", "C:\Window_${computerName}_result")

foreach ($dir in $directories) {
    Remove-Item -Path $dir -Recurse -ErrorAction SilentlyContinue
    New-Item -Path $dir -ItemType Directory | Out-Null
}

# Export security policy and gather system info
secedit /export /cfg "$($directories[0])\Local_Security_Policy.txt"
Get-Location | Out-File "$($directories[0])\install_path.txt"
systeminfo | Out-File "$($directories[0])\systeminfo.txt"

# Analyze IIS configuration
$applicationHostConfigPath = "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
Get-Content $applicationHostConfigPath | Out-File "$($directories[0])\iis_setting.txt"
Select-String -Path "$($directories[0])\iis_setting.txt" -Pattern "physicalPath|bindingInformation" | Out-File "$($directories[0])\iis_path1.txt"

# Check for vulnerable directories
$serviceRunning = Get-Service W3SVC -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' }
$vulnerableDirs = @(
    "c:\program files\common files\system\msadc\sample",
    "c:\winnt\help\iishelp",
    "c:\inetpub\iissamples",
    "${env:SystemRoot}\System32\Inetsrv\IISADMPWD"
)
$vulnerableFound = $vulnerableDirs | Where-Object { Test-Path $_ }

if ($serviceRunning -and $vulnerableFound) {
    $json.Result = "Vulnerable"
    $json.Status += "Policy violation detected: Vulnerable directories found."
    $vulnerableFound | Out-File "$resultDir\W-Window-${computerName}-result.txt" -Append
} else {
    $json.Result = "Safe"
    $json.Status += "Compliant: No vulnerable directories found or IIS service not running."
}

# Capture results and output JSON
$vulnerableFound | Out-File "$($directories[1])\W-Window-${computerName}-rawdata.txt" -Append
$json | ConvertTo-Json -Depth 3 | Out-File "$($directories[1])\W-Window-${computerName}-diagnostic_result.json"
