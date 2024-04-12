# Define the JSON object for diagnostic results
$json = @{
    Category = "Account Management"
    Code = "W-27"
    RiskLevel = "High"
    DiagnosticItem = "Use of Decryptable Encryption for Password Storage"
    DiagnosticResult = "Good" # Assuming good as the default state
    CurrentStatus = @()
    Recommendation = "Use of Decryptable Encryption for Password Storage"
}

# Request administrator privileges if not already running as admin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File `"$PSCommandPath`"", "-Verb RunAs"
    exit
}

# Setup environment
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
$null = New-Item -Path "$rawDir\compare.txt" -ItemType File
Set-Location -Path $rawDir
(Get-Location).Path | Out-File "$rawDir\install_path.txt"
systeminfo | Out-File "$rawDir\systeminfo.txt"

# Analyze IIS configuration
Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config" | Out-File "$rawDir\iis_setting.txt"
Select-String -Path "$rawDir\iis_setting.txt" -Pattern "physicalPath|bindingInformation" | Out-File "$rawDir\iis_path1.txt"

# Check IISADMIN service account
$serviceStatus = Get-Service W3SVC -ErrorAction SilentlyContinue
if ($serviceStatus.Status -eq 'Running') {
    $iisAdminReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\IISADMIN" -Name "ObjectName" -ErrorAction SilentlyContinue
    if ($iisAdminReg.ObjectName -ne "LocalSystem") {
        $json.CurrentStatus += "IISADMIN service is not running under the LocalSystem account, which does not require special action."
    } else {
        $json.CurrentStatus += "IISADMIN service is running under the LocalSystem account, which is not recommended."
    }
} else {
    $json.CurrentStatus += "World Wide Web Publishing Service is not running, eliminating the need for IIS-related security configuration review."
}

# Capture result data and output JSON
"--------------------------------------W-27-------------------------------------" | Out-File "$resultDir\W-Window-$computerName-rawdata.txt" -Append
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W3SVC" -Name "ObjectName" | Out-File "$resultDir\W-Window-$computerName-rawdata.txt" -Append
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\IISADMIN" -Name "ObjectName" | Out-File "$resultDir\W-Window-$computerName-rawdata.txt" -Append
"net localgroup Administrators" | Out-File "$resultDir\W-Window-$computerName-rawdata.txt" -Append

# Save JSON results to a file
$json | ConvertTo-Json -Depth 3 | Out-File "$resultDir\W-Window-$computerName-diagnostic_result.json"
