# JSON data initialization
$json = @{
    Category = "Security Management"
    Code = "W-68"
    RiskLevel = "High"
    DiagnosticItem = "Disallow Anonymous Enumeration of SAM Accounts and Shares"
    DiagnosticResult = "Good"  # Assume good as the default value
    Status = @()
    Countermeasure = "Configure system policies to disallow anonymous enumeration"
}

# Check and request administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Setup environment and directories
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Windows_Security_Audit\${computerName}_raw"
$resultDir = "C:\Windows_Security_Audit\${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDir, $resultDir -Force | Out-Null

# Check for anonymous enumeration restrictions
try {
    $restrictAnonymous = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\LSA" -Name "restrictanonymous"
    $restrictAnonymousSAM = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\LSA" -Name "RestrictAnonymousSAM"

    if ($restrictAnonymous -eq 1 -and $restrictAnonymousSAM -eq 1) {
        $json.Status += "The system is properly configured to restrict anonymous SAM account and share enumeration."
    } else {
        $json.DiagnosticResult = "Vulnerable"
        $json.Status += "The system is not properly configured to restrict anonymous SAM account and share enumeration."
    }
} catch {
    $json.DiagnosticResult = "Error"
    $json.Status += "Failed to retrieve the policy settings for anonymous enumeration."
}

# Save JSON results to a file
$jsonFilePath = "$resultDir\W-68.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "Diagnostic results have been saved: $jsonFilePath"

# Clean up and script completion
Remove-Item "$rawDir\*" -Force
Write-Host "Script has completed. Results have been saved to $resultDir."
