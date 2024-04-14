# JSON data initialization
$json = @{
    Category = "Security Management"
    Code = "W-72"
    RiskLevel = "High"
    DiagnosticItem = "DOS Attack Defense Registry Settings"
    DiagnosticResult = "Good"  # Assume "Good" as the default value
    Status = @()
    Countermeasure = "Adjust registry settings for DOS attack defense"
}

# Check and request administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "$PSCommandPath", "-Verb", "RunAs"
    exit
}

# Environment setup and directory preparation
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

Remove-Item -Path $rawDir, $resultDir -Recurse -Force
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# W-72 Check: DOS attack defense related registry settings
# Example: Check the SynAttackProtect registry key
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
$synAttackProtect = Get-ItemProperty -Path $regPath -Name "SynAttackProtect" -ErrorAction SilentlyContinue

if ($synAttackProtect -and $synAttackProtect.SynAttackProtect -eq 1) {
    $json.Status += "SynAttackProtect is enabled, enhancing DOS attack defenses."
} else {
    $json.DiagnosticResult = "Vulnerable"
    $json.Status += "SynAttackProtect is disabled or not properly configured."
}

# Save JSON results to a file
$jsonFilePath = "$resultDir\W-72.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "Diagnostic results have been saved: $jsonFilePath"

# Summary of results and script completion
Get-Content -Path "$resultDir\W-72_${computerName}_diagnostic_results.json" | Out-File -FilePath "$resultDir\security_audit_summary.txt"
Write-Host "Results have been saved to $resultDir\security_audit_summary.txt."

# Cleanup and script termination
Remove-Item -Path "$rawDir\*" -Force
Write-Host "Script has completed."
