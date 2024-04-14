# Initialize JSON data structure
$json = @{
    Category = "Security Management"
    Code = "W-66"
    RiskLevel = "High"
    DiagnosticItem = "Remote system forced shutdown"
    DiagnosticResult = "Good"  # Assuming good as the default value
    Status = @()
    Mitigation = "Properly configure policy to allow or deny remote system shutdown"
}

# Check and request administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Environment setup
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Windows_Security_Audit\${computerName}_raw"
$resultDir = "C:\Windows_Security_Audit\${computerName}_result"

Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDir, $resultDir -Force | Out-Null

# Check the privilege for remote system shutdown
try {
    $shutdownPrivilege = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "SeRemoteShutdownPrivilege"
    if ($shutdownPrivilege -match "S-1-5-32-544") {
        $json.DiagnosticResult = "Vulnerable"
        $json.Status += "The privilege for remote system shutdown is only assigned to the Administrators group."
    } else {
        $json.Status += "The privilege for remote system shutdown is securely configured."
    }
} catch {
    $json.DiagnosticResult = "Error"
    $json.Status += "Failed to retrieve the remote shutdown privilege settings."
}

# Save JSON results to a file
$jsonFilePath = "$resultDir\W-66.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "Diagnostic results have been saved: $jsonFilePath"

# Summary of results
Write-Host "Results have been saved to $resultDir."

# Cleanup
Remove-Item "$rawDir\*" -Force
Write-Host "Script has completed."
