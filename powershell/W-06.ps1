$json = @{
    분류 = "계정관리"
    코드 = "W-06"
    위험도 = "상"
    진단항목 = "관리자 그룹에 최소한의 사용자 포함"
    진단결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "관리자 그룹에 최소한의 사용자 포함"
}

# Check for Administrator privileges
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "관리자 권한을 요청하는 중..."
    $currentScript = $MyInvocation.MyCommand.Definition
    Start-Process PowerShell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$currentScript`"" -Verb RunAs
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
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory -Force | Out-Null

# Get installation path
"$installPath" | Out-File "$rawDir\install_path.txt"

# Collect system information
systeminfo | Out-File "$rawDir\systeminfo.txt"

# IIS Configuration
$applicationHostConfig = Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig | Out-File "$rawDir\iis_setting.txt"
Get-Content "$env:WINDOWS\system32\inetsrv\MetaBase.xml" | Out-File "$rawDir\iis_setting.txt" -Append

# Check for "test" or "Guest" in Administrators group
$administrators = net localgroup Administrators
$nonCompliantAccounts = $administrators | Where-Object { $_ -match "test|Guest" }

# 관리자 그룹 멤버십 검사 후 JSON 객체 업데이트
if ($nonCompliantAccounts) {
    $json.진단결과 = "취약"
    $json.현황 += "관리자 그룹에 임시 또는 게스트 계정('test', 'Guest')이 포함되어 있습니다."
} else {
    $json.현황 += "관리자 그룹에 임시 또는 게스트 계정이 포함되지 않아 보안 정책을 준수합니다."
}

# JSON 결과를 파일로 저장
$jsonFilePath = "$resultDir\W-Window-${computerName}-diagnostic_result_1.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
