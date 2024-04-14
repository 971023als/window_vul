# Initialize the JSON object
$json = @{
    Category = "Security Management"
    Code = "W-73"
    RiskLevel = "High"
    DiagnosticItem = "Prevent users from installing printer drivers"
    DiagnosticResult = "Good"  # Assume the default value is "Good"
    Status = @()
    Countermeasure = "Adjust settings to prevent users from installing printer drivers"
}

# Request administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Verb RunAs"
    exit
}

# Setup the environment and directory structure
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# Export local security policy
secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null

# Verify printer driver installation permissions
$securityPolicy = Get-Content "$rawDir\Local_Security_Policy.txt"
$addPrinterDrivers = $securityPolicy | Where-Object { $_ -match "AddPrinterDrivers" -and $_ -match "= 0" }

if ($addPrinterDrivers) {
    $json.DiagnosticResult = "Vulnerable"
    $json.Status += "Printer driver installation permission is not set appropriately."
} else {
    $json.Status += "Printer driver installation permission is set appropriately."
}

# JSON results storage
$jsonFilePath = "$resultDir\W-73.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "Diagnostic results have been saved: $jsonFilePath"

# Cleanup
Remove-Item "$rawDir\*" -Force -ErrorAction SilentlyContinue

Write-Host "Script has completed."
