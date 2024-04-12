$json = @{
    Category = "Account Management"
    Code = "W-28"
    RiskLevel = "High"
    DiagnosticItem = "Use of Decryptable Encryption for Password Storage"
    DiagnosticResult = "Good"  # Assuming good as the default state
    CurrentStatus = @()
    Recommendation = "Avoid using decryptable encryption for password storage"
}

# Request administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File `"$PSCommandPath`"", "-Verb RunAs"
    exit
}

# Setup environment and directories
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
$null = New-Item -Path "$rawDir\compare.txt" -ItemType File
Set-Location -Path $rawDir
[System.IO.File]::WriteAllText("$rawDir\install_path.txt", (Get-Location).Path)
systeminfo | Out-File "$rawDir\systeminfo.txt"

# Analyze IIS configuration
$applicationHostConfig = Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig | Out-File "$rawDir\iis_setting.txt"
$applicationHostConfig | Select-String -Pattern "physicalPath|bindingInformation" | Out-File "$rawDir\iis_path1.txt"

# Check for shortcut files in critical IIS paths
$serviceStatus = Get-Service W3SVC -ErrorAction SilentlyContinue
if ($serviceStatus.Status -eq 'Running') {
    $shortcutFound = $False
    1..5 | ForEach-Object {
        $path = Get-Content "$rawDir\path$_.txt" -ErrorAction SilentlyContinue
        if (Test-Path $path) {
            $shortcutFiles = Get-ChildItem -Path $path -Filter "*.lnk"
            if ($shortcutFiles) {
                $shortcutFound = $True
                "$path contains shortcut files (*.lnk), posing a security risk." | Out-File "$rawDir\W-28-findings.txt" -Append
            }
        }
    }

    if ($shortcutFound) {
        $json.CurrentStatus += "Shortcut files found in critical IIS paths, indicating a security risk."
        $json.DiagnosticResult = "Vulnerable"
    } else {
        $json.CurrentStatus += "No unauthorized shortcut files found in critical IIS paths, system complies with security standards."
    }
} else {
    $json.CurrentStatus += "World Wide Web Publishing Service is not running, no need to check for shortcut files."
}

# Output diagnostic results and capture data
$json | ConvertTo-Json -Depth 3 | Out-File "$resultDir\W-Window-${computerName}-diagnostic_result.json"
if (Test-Path "$rawDir\W-28-findings.txt") {
    Get-Content "$rawDir\W-28-findings.txt" | Out-File "$resultDir\W-Window-${computerName}-rawdata.txt"
}
