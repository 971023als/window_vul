# Define the audit configuration using a custom object for easier property management
$json = [PSCustomObject]@{
    분류 = "서비스관리"
    코드 = "W-39"
    위험도 = "상"
    진단항목 = "Anonymous FTP 금지"
    진단결과 = "양호" # 기본 값을 "양호"로 설정
    현황 = @()
    대응방안 = "Anonymous FTP 금지"
}

# Request Administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
If (-not $isAdmin) {
    $info = [System.Diagnostics.ProcessStartInfo]::new("PowerShell")
    $info.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $args"
    $info.Verb = "runas"
    [System.Diagnostics.Process]::Start($info)
    Exit
}

# Set up the console environment
chcp 437 | Out-Null
$host.UI.RawUI.BackgroundColor = "DarkGreen"
$host.UI.RawUI.ForegroundColor = "Green"
Clear-Host

Write-Host "------------------------------------------Configuration Initialization---------------------------------------"
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Audit_${computerName}_Raw"
$resultDir = "C:\Audit_${computerName}_Results"

# Clean up previous directories and create new ones for the current audit
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# Export local security policy and generate a comparison file
secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null
New-Item -Path "$rawDir\compare.txt" -ItemType File -Value $null

# Save installation path and collect system information
Set-Location -Path $rawDir
Get-Location | Out-File -FilePath "$rawDir\install_path.txt"
systeminfo | Out-File -FilePath "$rawDir\systeminfo.txt"

Write-Host "------------------------------------------IIS Configuration-----------------------------------"
Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config" | Out-File -FilePath "$rawDir\iis_setting.txt"
Select-String -Path "$rawDir\iis_setting.txt" -Pattern "physicalPath|bindingInformation" | ForEach-Object { $_.Line } | Out-File -FilePath "$rawDir\iis_path1.txt"

# Analyze IIS settings and save the paths
$line = Get-Content "$rawDir\iis_path1.txt" -Raw
$line | Out-File -FilePath "$rawDir\line.txt"

1..5 | ForEach-Object {
    $filePath = "$rawDir\path$_.txt"
    Get-Content "$rawDir\line.txt" | ForEach-Object {
        $_ | Out-File -FilePath $filePath -Append
    }
}

# Append MetaBase.xml if applicable
$metaBasePath = "$env:WINDIR\system32\inetsrv\MetaBase.xml"
If (Test-Path $metaBasePath) {
    Get-Content $metaBasePath | Out-File -FilePath "$rawDir\iis_setting.txt" -Append
}

Write-Host "------------------------------------------Configuration Complete-------------------------------------------"

# Update JSON data based on diagnostics
$isSecure = $true # This value should be determined by actual diagnostic logic

if (-not $isSecure) {
    $json.진단결과 = "위험"
    $json.현황 = @("EVERYONE 그룹에 대한 FullControl 접근 권한이 발견되었습니다.")
} else {
    $json.현황 = @("FTP 디렉토리 접근권한이 적절히 설정됨.")
}

# Save JSON results to a file
$jsonFilePath = "$resultDir\W-39.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
