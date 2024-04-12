$json = @{
    분류 = "계정관리"
    코드 = "W-07"
    위험도 = "상"
    진단항목 = "Everyone 사용 권한을 익명 사용자에게 적용"
    진단결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "Everyone 사용 권한을 익명 사용자에게 적용하지 않도록 설정"
}

# Check for Administrator privileges
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "관리자 권한을 요청 중입니다..."
    $script = $MyInvocation.MyCommand.Definition
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$script`"" -Verb RunAs
    Exit
}

# Set console preferences
[Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding(437)
$host.UI.RawUI.BackgroundColor = "DarkGreen"
$host.UI.RawUI.ForegroundColor = "Green"
Clear-Host

# Initial setup
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null
New-Item -Path "$rawDir\compare.txt" -ItemType File

# Get installation path
$installPath = Get-Location
"$installPath" | Out-File "$rawDir\install_path.txt"

# Collect system information
systeminfo | Out-File "$rawDir\systeminfo.txt"

# IIS Configuration
$applicationHostConfig = Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig | Out-File "$rawDir\iis_setting.txt"
Get-Content "$env:WINDOWS\system32\inetsrv\MetaBase.xml" | Out-File "$rawDir\iis_setting.txt" -Append

# Check "EveryoneIncludesAnonymous" policy
$localSecurityPolicy = Get-Content "$rawDir\Local_Security_Policy.txt"
$everyoneIncludesAnonymous = $localSecurityPolicy | Where-Object { $_ -match "EveryoneIncludesAnonymous" }

# "EveryoneIncludesAnonymous" 정책 검사 후 JSON 객체 업데이트
if ($everyoneIncludesAnonymous -match "0") {
    $json.현황 += "'모든 사용자가 익명 사용자를 포함' 정책이 '사용 안 함'으로 올바르게 설정되어 더 높은 보안을 보장합니다."
} else {
    $json.진단결과 = "취약"
    $json.현황 += "'모든 사용자가 익명 사용자를 포함' 정책이 '사용 안 함'으로 설정되지 않아 잠재적 보안 위험을 초래합니다."
}

# JSON 결과를 파일로 저장
$jsonFilePath = "$resultDir\W-Window-${computerName}-diagnostic_result.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
