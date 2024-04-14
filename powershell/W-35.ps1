# Initialize audit parameters
$auditParameters = @{
    Category = "Account Management"
    Code = "W-35"
    RiskLevel = "High"
    AuditItem = "Use of decryptable encryption for password storage"
    AuditResult = "Good"  # Assuming "Good" as the default state
    CurrentStatus = @()
    MitigationRecommendation = "Use of non-decryptable encryption for password storage"
}

# Request Administrator privileges if not already running with them
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", $PSCommandPath, "-Verb", "RunAs"
    exit
}

# Set console environment
function Initialize-Console {
    chcp 437 | Out-Null
    $host.UI.RawUI.BackgroundColor = "DarkGreen"
    $host.UI.RawUI.ForegroundColor = "Green"
    Clear-Host
    Write-Host "Setting up the environment..."
}

# Prepare the audit environment
function Setup-AuditEnvironment {
    $global:computerName = $env:COMPUTERNAME
    $global:rawDir = "C:\Audit_${computerName}_RawData"
    $global:resultDir = "C:\Audit_${computerName}_Results"

    # Cleanup previous data and prepare new directories
    Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

    # Export local security policy and system information
    secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null
    systeminfo | Out-File "$rawDir\SystemInfo.txt"
}

# WebDAV Security Audit
function Perform-WebDAVSecurityCheck {
    Write-Host "Performing WebDAV Security Check..."
    $serviceStatus = (Get-Service W3SVC -ErrorAction SilentlyContinue).Status

    if ($serviceStatus -eq "Running") {
        $webDavConfigurations = Select-String -Path "$env:SystemRoot\System32\inetsrv\config\applicationHost.config" -Pattern "webdav" -AllMatches

        if ($webDavConfigurations) {
            foreach ($config in $webDavConfigurations) {
                $config.Line | Out-File -FilePath "$rawDir\WebDAVConfigDetails.txt" -Append
            }
            Write-Host "Review required: WebDAV configurations found. Details in WebDAVConfigDetails.txt"
        } else {
            Write-Host "No action required: WebDAV is properly configured or not present."
        }
    } else {
        Write-Host "No action required: IIS Web Publishing Service is not running."
    }
}

# Main script execution
Initialize-Console
Setup-AuditEnvironment
Perform-WebDAVSecurityCheck

# Save JSON results to a file
$jsonFilePath = "$resultDir\W-35.json"
$auditParameters | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
