# JSON data initialization
$json = @{
    Category = "Security Management"
    Code = "W-71"
    RiskLevel = "High"
    DiagnosticItem = "Disk Volume Encryption Settings"
    DiagnosticResult = "Good"  # Assume "Good" as the default value
    Status = @()
    Countermeasure = "Strengthen data protection through disk volume encryption settings"
}

# Check and request administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "$($MyInvocation.MyCommand.Definition)" -Verb RunAs
    exit
}

$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# Clear previous data and create directories
Remove-Item -Path $rawDir, $resultDir -Recurse -Force
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# Check disk volume encryption settings
# Example: Check BitLocker status (adjust as necessary for your environment)
try {
    $bitLockerStatus = Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop | Select-Object -ExpandProperty ProtectionStatus

    if ($bitLockerStatus -eq 1) {
        $json.Status += "The C: drive is encrypted with BitLocker."
    } else {
        $json.DiagnosticResult = "Vulnerable"
        $json.Status += "The C: drive is not encrypted with BitLocker."
    }
} catch {
    $json.DiagnosticResult = "Error"
    $json.Status += "Failed to retrieve BitLocker status, possible that BitLocker is not present on this system."
}

# Save JSON results to a file
$jsonFilePath = "$resultDir\W-71.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "Diagnostic results have been saved: $jsonFilePath"

# Summarize results and output
Get-Content -Path "$resultDir\W-71_${computerName}_diagnostic_results.json" | Out-File -FilePath "$resultDir\security_audit_summary.txt"
Write-Host "Results have been saved to $resultDir\security_audit_summary.txt."

# Cleanup and script completion message
Remove-Item "$rawDir\*" -Force
Write-Host "Script has completed."
