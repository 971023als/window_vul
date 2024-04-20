# Initialize JSON data structure
$json = @{
    Category = "Security Management"
    Code = "W-65"
    RiskLevel = "High"
    DiagnosticItem = "Allow shutdown without logon"
    DiagnosticResult = "Good"  # Assuming good as the default
    Status = @()
    Mitigation = "Adjust policies to allow or block shutdown without logon"
}

# Check and request administrator privileges
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$windowsPrincipal = New-Object Security.Principal.WindowsPrincipal($currentUser)
if (-not $windowsPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "$PSCommandPath" -Verb RunAs
    exit
}

# Environment setup and directory creation
$computerName = $env:COMPUTERNAME
$resultDir = "C:\Window_${computerName}_result"

if (Test-Path $resultDir) {
    Remove-Item -Path $resultDir -Recurse
}
New-Item -ItemType Directory -Path $resultDir | Out-Null

# Check the policy for "Shutdown without logon"
$shutdownWithoutLogon = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System").ShutdownWithoutLogon

# Record results and update JSON
if ($shutdownWithoutLogon -eq 0) {
    $json.DiagnosticResult = "Vulnerable"
    $json.Status += "Vulnerable: The policy 'Allow system to be shut down without having to log on' is disabled."
} else {
    $json.Status += "Safe: The policy 'Allow system to be shut down without having to log on' is enabled."
}

# Save JSON results to a file
$jsonFilePath = "$resultDir\W-65.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "Diagnostic results have been saved: $jsonFilePath"

# Summarize results and end script
Write-Host "Results have been saved to $resultDir."
Write-Host "Script has completed."
