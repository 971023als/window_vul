# Initialize JSON data structure
$json = @{
    Category = "Security Management"
    Code = "W-67"
    RiskLevel = "High"
    DiagnosticItem = "Shut down system immediately if unable to log security audits"
    DiagnosticResult = "Good"  # Assuming good as the default value
    Status = @()
    Countermeasure = "Properly configure the policy to shut down the system if unable to log security audits"
}

# Check and request administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Setup environment and directories
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDir, $resultDir -Force | Out-Null

# Check the system policy for handling audit failures
try {
    $policyValue = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "CrashOnAuditFail"
    if ($policyValue.CrashOnAuditFail -eq 1) {
        $json.DiagnosticResult = "Good"
        $json.Status += "The system is configured to shut down if it is unable to log security audits, enhancing security."
    } else {
        $json.DiagnosticResult = "Vulnerable"
        $json.Status += "The system is not configured to shut down if it is unable to log security audits, which may pose a security risk."
    }
} catch {
    $json.DiagnosticResult = "Error"
    $json.Status += "Failed to retrieve the policy setting for audit failure handling."
}

# Save JSON results to a file
$jsonFilePath = "$resultDir\W-67.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "Diagnostic results have been saved: $jsonFilePath"

# Clean up and exit script
Remove-Item -Path "$rawDir\*" -Force
Write-Host "Script has completed. Results have been saved to $resultDirectory."
