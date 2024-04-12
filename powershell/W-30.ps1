$json = @{
    Category = "Account Management"
    Code = "W-30"
    RiskLevel = "High"
    DiagnosticItem = "Use of Decryptable Encryption for Password Storage"
    DiagnosticResult = "Good"  # Assuming good as the default state
    CurrentStatus = @()
    Recommendation = "Use non-decryptable encryption for password storage"
}

# Request Administrator Privileges
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "`"$PSCommandPath`"" -Verb RunAs
    exit
}

# Console Configuration
chcp 437 > $null
$host.UI.RawUI.BackgroundColor = "DarkGreen"
$host.UI.RawUI.ForegroundColor = "Green"
Clear-Host

# Setup Environment
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory -Force | Out-Null

# Export Local Security Policy
secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null

# Save Installation Path
(Get-Location).Path | Out-File -FilePath "$rawDir\install_path.txt"

# Save System Information
systeminfo | Out-File -FilePath "$rawDir\systeminfo.txt"

# IIS Configuration Analysis
$applicationHostConfig = "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
Get-Content -Path $applicationHostConfig | Out-File -FilePath "$rawDir\iis_setting.txt"
Select-String -Path "$rawDir\iis_setting.txt" -Pattern "physicalPath|bindingInformation" | Out-File "$rawDir\iis_path1.txt"

# Copy MetaBase.xml if applicable
$metaBasePath = "$env:WINDIR\system32\inetsrv\MetaBase.xml"
If (Test-Path $metaBasePath) {
    Get-Content -Path $metaBasePath | Out-File -FilePath "$rawDir\iis_setting.txt" -Append
}

# W-30 Diagnostic Check
If ((Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue).Status -eq "Running") {
    $asaFiles = Select-String -Path "$rawDir\iis_setting.txt" -Pattern "\.asax|\.asa"
    If ($asaFiles) {
        "W-30,X,| Policy Violation: Unrestricted access to .asa or .asax files detected." | Out-File -FilePath "$resultDir\W-Window-$computerName-result.txt" -Append
    } Else {
        "W-30,O,| Policy Compliance: .asa and .asax files are appropriately restricted." | Out-File -FilePath "$resultDir\W-Window-$computerName-result.txt" -Append
    }
} Else {
    "W-30,O,| World Wide Web Publishing Service is not running: No need to check for .asa or .asax files." | Out-File -FilePath "$resultDir\W-Window-$computerName-result.txt" -Append
}
