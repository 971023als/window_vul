# JSON data initialization
$json = @{
    Category = "Security Management"
    Code = "W-70"
    RiskLevel = "High"
    DiagnosticItem = "Allow Formatting and Ejecting of Removable Media"
    DiagnosticResult = "Good"  # Assume "Good" as the default value
    Status = @()
    Countermeasure = "Proper control over formatting and ejecting of removable media"
}

# Check and request administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Environment setup and directory creation
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDir, $resultDir -Force | Out-Null

# Export and analyze local security policy
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
$localSecurityPolicy = Get-Content "$rawDir\Local_Security_Policy.txt"
$allocateDASD = $localSecurityPolicy | Where-Object { $_ -match "AllocateDASD" -and $_ -notmatch "0" }

# Update JSON based on analysis
if ($allocateDASD) {
    $json.Status += "Disk allocation permission changes are restricted to administrators only."
} else {
    $json.DiagnosticResult = "Vulnerable"
    $json.Status += "Disk allocation permission changes are not restricted to administrators only."
}

# Save JSON results to a file
$jsonFilePath = "$resultDir\W-70.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "Diagnostic results have been saved: $jsonFilePath"

# Summarize results and save
Get-Content -Path "$resultDir\W-70_${computerName}_diagnostic_results.json" | Out-File -FilePath "$resultDir\security_audit_summary.txt"
Write-Host "Results have been saved to $resultDir\security_audit_summary.txt."

# Cleanup and script completion message
Remove-Item "$rawDir\*" -Force
Write-Host "Script has completed."
