# PowerShell Script for Security Audit (Focused on IIS Version and Configuration)

# Define audit parameters in a hashtable for easy reference and update
$auditParams = @{
    Category = "Account Management"
    Code = "W-34"
    RiskLevel = "High"
    AuditItem = "Use of decryptable encryption for password storage"
    AuditResult = "Good"  # Assuming good as the default state
    CurrentStatus = @()
    Mitigation = "Use of non-decryptable encryption for password storage"
}

# Request Administrator privileges if not already running with them
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "`"$PSCommandPath`"", "-Verb", "RunAs"
    exit
}

# Initial setup
$computerName = $env:COMPUTERNAME
$dirs = @{
    Raw = "C:\Window_${computerName}_raw"
    Result = "C:\Window_${computerName}_result"
}

# Prepare environment
function Initialize-Environment {
    chcp 437 | Out-Null
    $host.UI.RawUI.BackgroundColor = "DarkGreen"
    $host.UI.RawUI.ForegroundColor = "Green"
    Clear-Host

    Write-Host "Setting up the environment..."
    Remove-Item -Path $dirs.Raw, $dirs.Result -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -Path $dirs.Raw, $dirs.Result -ItemType Directory | Out-Null

    secedit /export /cfg "$($dirs.Raw)\Local_Security_Policy.txt"
    New-Item -Path "$($dirs.Raw)\compare.txt" -ItemType File -Value $null

    systeminfo | Out-File -FilePath "$($dirs.Raw)\systeminfo.txt"
}

# IIS Configuration Analysis
function Analyze-IISConfiguration {
    Write-Host "Analyzing IIS Settings..."
    $applicationHostConfig = Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
    $applicationHostConfig | Out-File -FilePath "$($dirs.Raw)\iis_setting.txt"

    # Detect if the server is using IIS 5.0 or below, which is deprecated
    if ($applicationHostConfig -match "IIS5") {
        $auditParams.CurrentStatus += "Deprecated IIS version detected. Upgrade required."
        $auditParams.AuditResult = "Vulnerable"
    } else {
        $auditParams.CurrentStatus += "No deprecated IIS version detected. Compliant with security standards."
    }
}

# Execute the script steps
Initialize-Environment
Analyze-IISConfiguration

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-34.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
