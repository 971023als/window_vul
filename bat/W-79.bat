# Define JSON data structure for security audit results
$json = @{
    "분류" = "보안관리"
    "코드" = "W-79"
    "위험도" = "상"
    "진단 항목" = "파일 및 디렉토리 보호"
    "진단 결과" = "양호" # Assume the default value is "Good"
    "현황" = @()
    "대응방안" = "파일 및 디렉토리 보호"
}

# Request administrator privileges if not already running as admin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Re-running the script with administrator privileges."
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", $PSCommandPath -Verb RunAs
    exit
}

$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# Create or clean directories
$dirs = @($rawDir, $resultDir)
foreach ($dir in $dirs) {
    if (Test-Path $dir) {
        Remove-Item $dir -Recurse -Force
    }
    New-Item -Path $dir -ItemType Directory | Out-Null
}

# Export local security policy and collect system information
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
systeminfo | Out-File "$rawDir\systeminfo.txt"

# Analyze IIS configuration if applicable
$iisConfigPath = "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
if (Test-Path $iisConfigPath) {
    Get-Content $iisConfigPath | Select-String "physicalPath|bindingInformation" | Out-File "$rawDir\iis_setting.txt"
}

# NTFS permissions check
$aclCheckPath = "C:\" # Change this path as necessary for targeted audits
if (Test-Path $aclCheckPath) {
    $ntfsCheck = (Get-Acl $aclCheckPath).AccessToString -match "NT AUTHORITY"
    if ($ntfsCheck) {
        $json.현황 += "NTFS 권한이 적절히 설정되어 있습니다."
    } else {
        $json.'진단 결과' = "취약"
        $json.현황 += "NTFS 권한 설정이 적절하지 않습니다."
        "W-79,X,| NTFS 권한 설정이 적절하지 않습니다." | Out-File "$resultDir\W-Window-$computerName-result.txt"
    }
}

# Save JSON results to a file
$jsonFilePath = "$resultDir\W-79.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath

# Summarize results
Get-Content "$resultDir\W-Window-*" | Out-File "$resultDir\security_audit_summary.txt"

# Cleanup
Remove-Item "$rawDir\*" -Force
Write-Host "The script has completed. Check the results in $resultDir."
