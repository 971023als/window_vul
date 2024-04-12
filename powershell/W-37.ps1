# PowerShell Script for Auditing Microsoft FTP Service

# Define the audit configuration
$auditConfig = @{
    Category    = "Account Management"
    Code        = "W-37"
    RiskLevel   = "High"
    AuditItem   = "Use of decryptable encryption for password storage"
    AuditResult = "Good"  # Default value
    Status      = @()
    Recommendation = "Use of non-decryptable encryption for password storage"
}

# Request Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", $PSCommandPath, "-Verb", "RunAs"
    Exit
}

# Setup console environment
function Initialize-Environment {
    chcp 437 | Out-Null
    $host.UI.RawUI.BackgroundColor = "DarkGreen"
    $host.UI.RawUI.ForegroundColor = "Green"
    Clear-Host
    Write-Host "Initializing environment..."
}

# Setup and cleanup audit directories
function Setup-Directories {
    $global:computerName = $env:COMPUTERNAME
    $global:rawDir = "C:\Audit_${computerName}_Raw"
    $global:resultDir = "C:\Audit_${computerName}_Results"

    Remove-Item $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item $rawDir, $resultDir -ItemType Directory | Out-Null
    Write-Host "Directories setup complete."
}

# Export local security policy and collect system info
function Export-PolicyAndCollect-Info {
    secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null
    systeminfo | Out-File "$rawDir\SystemInfo.txt"
    Write-Host "Local security policy exported and system information collected."
}

# Audit Microsoft FTP Service
function Audit-FTPServices {
    Write-Host "Auditing Microsoft FTP Service..."
    $ftpService = Get-Service -Name "MSFTPSVC" -ErrorAction SilentlyContinue
    if ($ftpService.Status -eq "Running") {
        "W-37, Warning, | Microsoft FTP Service is running, which may present a vulnerability." | Out-File "$resultDir\W-Window-${computerName}-Result.txt"
        Write-Host "Warning: Microsoft FTP Service is running. Consider disabling if not required."
    } else {
        "W-37, Secure, | Microsoft FTP Service is not running. No action required." | Out-File "$resultDir\W-Window-${computerName}-Result.txt"
        Write-Host "Secure: Microsoft FTP Service is not running."
    }
}

# Main
Initialize-Environment
Setup-Directories
Export-PolicyAndCollect-Info
Audit-FTPServices

Write-Host "Audit complete. Review the results in the Results directory."
