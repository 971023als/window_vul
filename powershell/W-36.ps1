# PowerShell Script for NetBIOS Configuration Audit

# Define the audit parameters
$auditParams = @{
    Category = "Account Management"
    Code = "W-36"
    RiskLevel = "High"
    AuditItem = "Use of decryptable encryption for password storage"
    AuditResult = "Good"  # Assuming "Good" as the default value
    Status = @()
    Recommendation = "Use of non-decryptable encryption for password storage"
}

# Ensure the script runs with Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", $PSCommandPath, "-Verb", "RunAs"
    exit
}

# Configure the console environment
function Setup-Console {
    chcp 437 | Out-Null
    $host.UI.RawUI.BackgroundColor = "DarkGreen"
    $host.UI.RawUI.ForegroundColor = "Green"
    Clear-Host
    Write-Host "Initializing audit environment..."
}

# Setup audit environment
function Initialize-AuditEnvironment {
    $global:computerName = $env:COMPUTERNAME
    $global:rawDir = "C:\Audit_${computerName}_Raw"
    $global:resultDir = "C:\Audit_${computerName}_Results"

    # Clean up previous data and set up directories for current audit
    Remove-Item $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item $rawDir, $resultDir -ItemType Directory | Out-Null
    secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
    systeminfo | Out-File "$rawDir\SystemInfo.txt"
}

# Perform NetBIOS Configuration Check
function Check-NetBIOSConfiguration {
    Write-Host "Checking NetBIOS Configuration..."
    $netBIOSConfig = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.TcpipNetbiosOptions -eq 2 }

    if ($netBIOSConfig) {
        "W-36, Good, | NetBIOS over TCP/IP is disabled, aligning with secure configuration recommendations." | Out-File "$resultDir\W-Window-${computerName}-Result.txt"
        Write-Host "NetBIOS over TCP/IP is disabled - configuration is secure."
    } else {
        "W-36, Attention Needed, | Review NetBIOS over TCP/IP settings for potential security improvements." | Out-File "$resultDir\W-Window-${computerName}-Result.txt"
        Write-Host "Attention Needed: Review NetBIOS over TCP/IP settings."
    }
}

# Summarize audit findings and perform cleanup
function Finalize-Audit {
    Write-Host "Audit Completed. Review the results in $resultDir."
    Remove-Item "$rawDir\*" -Force -ErrorAction SilentlyContinue
}

# Main
Setup-Console
Initialize-AuditEnvironment
Check-NetBIOSConfiguration
Finalize-Audit
