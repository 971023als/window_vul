# Define the initial JSON structure
$json = @{
    분류 = "보안관리"
    코드 = "W-76"
    위험도 = "상"
    진단 항목 = "사용자별 홈 디렉터리 권한 설정"
    진단 결과 = "양호"  # Assume the default value is "Good"
    현황 = @()
    대응방안 = "사용자별 홈 디렉터리 권한 설정"
}

# Request administrator privileges if not already running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File `"$PSCommandPath`"", "-Verb", "RunAs"
    exit
}

# Setup environment
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# Delete existing data and create directories for new data
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDir, $resultDir | Out-Null

# Export local security policy
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"

# Analyze user home directory permissions
$users = Get-ChildItem C:\Users -Directory | Where-Object { $_.Name -notmatch '^(Public|Default.*|All Users)$' }
foreach ($user in $users) {
    $acl = Get-Acl "C:\Users\$($user.Name)"
    foreach ($ace in $acl.Access) {
        if ($ace.FileSystemRights -match "FullControl" -and $ace.IdentityReference -eq "Everyone") {
            $json.현황 += "취약: Everyone 그룹에 전체 제어 권한이 설정된 사용자 - $($user.Name)"
            $json.진단 결과 = "취약"
        }
    }
}

# Confirm diagnostic results based on the findings
if ($json.진단 결과 -eq "양호") {
    $json.현황 += "모든 사용자의 홈 디렉터리 권한이 적절하게 설정되어 있습니다."
}

# Save JSON results to a file
$jsonFilePath = "$resultDir\W-76.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# Clean up
Remove-Item "$rawDir\*" -Force
Write-Host "스크립트가 완료되었습니다."
