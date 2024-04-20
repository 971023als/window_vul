# Initialize JSON object for diagnostics
$json = @{
    분류 = "서비스관리"
    코드 = "W-24"
    위험도 = "상"
    진단 항목 = "IIS CGI 실행 제한"
    진단 결과 = "양호"  # Assuming 'Good' as the default
    현황 = @()
    대응방안 = "IIS CGI 실행 제한"
}

# Request Administrator privileges
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "$PSCommandPath", "-Verb", "RunAs"
    Exit
}

# Console environment and initial setup
chcp 949 | Out-Null
$host.UI.RawUI.ForegroundColor = "Green"

$computerName = $env:COMPUTERNAME
$directories = @("C:\Window_${computerName}_raw", "C:\Window_${computerName}_result")
foreach ($dir in $directories) {
    If (Test-Path $dir) { Remove-Item -Path $dir -Recurse -Force }
    New-Item -Path $dir -ItemType Directory | Out-Null
}

# Export local security policy and system information
secedit /export /cfg "$($directories[0])\Local_Security_Policy.txt"
Get-Location | Out-File "$($directories[0])\install_path.txt"
systeminfo | Out-File "$($directories[0])\systeminfo.txt"

# Analyze IIS settings
$applicationHostConfig = Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig | Out-File "$($directories[0])\iis_setting.txt"

# Folder permissions audit
$serviceStatus = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
$foldersToCheck = @("C:\inetpub\scripts", "C:\inetpub\cgi-bin")
$hasPermissionIssue = $false

If ($serviceStatus.Status -eq "Running") {
    foreach ($folder in $foldersToCheck) {
        If (Test-Path $folder) {
            $acl = Get-Acl $folder
            foreach ($access in $acl.Access) {
                If ($access.FileSystemRights -match "Write|Modify|FullControl" -and $access.IdentityReference -eq "Everyone") {
                    $hasPermissionIssue = $true
                    $json.현황 += "$folder has write/modify/full control permission for Everyone"
                }
            }
        }
    }

    $json.진단 결과 = If ($hasPermissionIssue) { "취약" } else { "양호" }
    $json.현황 += If ($hasPermissionIssue) { "정책 위반: Excessive permissions found." } else { "정책 준수: Appropriate permissions set." }
} Else {
    $json.현황 += "정책 준수: IIS 서비스가 비활성화된 상태."
    $json.진단 결과 = "양호"
}

# Save the JSON results to a file
$jsonFilePath = "$resultDir\W-24.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
