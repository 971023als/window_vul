# JSON data initialization
$json = @{
    Category = "Security Management"
    Code = "W-69"
    RiskLevel = "High"
    DiagnosticItem = "Control of Autologon Function"
    DiagnosticResult = "Good"  # Assume good as the default value
    Status = @()
    Countermeasure = "Disable the Autologon function to enhance security"
}

# Check and request administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Environment setup and directory creation
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDir, $resultDir -Force | Out-Null

# Check Autologon settings
$autoAdminLogon = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon").AutoAdminLogon

if ($autoAdminLogon -eq "1") {
    $json.DiagnosticResult = "Vulnerable"
    $json.Status += "AutoAdminLogon is enabled, posing a security risk."
} else {
    $json.Status += "AutoAdminLogon is disabled, enhancing system security."
}

# Save JSON results to a file
$jsonFilePath = "$resultDir\W-69.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "Diagnostic results have been saved: $jsonFilePath"

# Summarize and save results
Get-Content -Path "$resultDir\W-69_${computerName}_diagnostic_results.json" | Out-File -FilePath "$resultDir\security_audit_summary.txt"
Write-Host "Results have been saved to $resultDir\security_audit_summary.txt."

# Cleanup and script completion message
Remove-Item -Path "$rawDir\*" -Force
Write-Host "Script has completed."
