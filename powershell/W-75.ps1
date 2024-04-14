# Initialize the JSON object for diagnostic results
$json = @{
    Category = "Security Management"
    Code = "W-75"
    RiskLevel = "High"
    DiagnosticItem = "Login Warning Message Settings"
    DiagnosticResult = "Good"  # Assume the default value is "Good"
    Status = @()
    Countermeasure = "Adjust Login Warning Message Settings"
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

# Check login legal notice settings
$winlogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$LegalNoticeCaption = (Get-ItemProperty -Path $winlogonPath -Name "LegalNoticeCaption" -ErrorAction SilentlyContinue).LegalNoticeCaption
$LegalNoticeText = (Get-ItemProperty -Path $winlogonPath -Name "LegalNoticeText" -ErrorAction SilentlyContinue).LegalNoticeText

if ([string]::IsNullOrEmpty($LegalNoticeCaption) -and [string]::IsNullOrEmpty($LegalNoticeText)) {
    $json.Status += "No login warning message is set, which is secure."
} else {
    $json.DiagnosticResult = "Vulnerable"
    $json.Status += "Login warning message is set, which may not be secure depending on content."
}

# Save the JSON results to a file
$jsonFilePath = "$resultDir\W-75.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "Diagnostic results have been saved: $jsonFilePath"

# Cleanup
Remove-Item "$rawDir\*" -Force

Write-Host "Script has completed successfully."
