# Initialize the JSON object for diagnostic results
$json = @{
    Category = "Security Management"
    Code = "W-74"
    RiskLevel = "High"
    DiagnosticItem = "Required idle time before disconnecting a session"
    DiagnosticResult = "Good"  # Assume the default value is "Good"
    Status = @()
    Countermeasure = "Adjust settings for required idle time before session disconnection"
}

# Request administrator privileges if not already running as an administrator
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File `"$PSCommandPath`"", "-Verb", "RunAs"
    Exit
}

# Setup environment and directories
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# Delete existing data and create directories for new audit data
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# Export local security policy to a file
secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null

# Check LanManServer parameter settings for forced logoff and auto-disconnect
$lanManServerParams = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanManServer\Parameters"
$enableForcedLogOff = $lanManServerParams.EnableForcedLogOff
$autoDisconnect = $lanManServerParams.AutoDisconnect

if ($enableForcedLogOff -eq 1 -and $autoDisconnect -eq 15) {
    $json.Status += "The server settings for forced logoff and auto-disconnect are appropriately configured."
} else {
    $json.DiagnosticResult = "Vulnerable"
    $json.Status += "The server settings for forced logoff and auto-disconnect are not appropriately configured."
}

# Save the JSON results to a file
$jsonFilePath = "$resultDir\W-74.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "Diagnostic results have been saved: $jsonFilePath"

# Cleanup
Remove-Item "$rawDir\*" -Force

Write-Host "Script has completed successfully."
