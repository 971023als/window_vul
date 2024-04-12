$json = @{
    분류 = "계정관리"
    코드 = "W-05"
    위험도 = "상"
    진단항목 = "해독 가능한 암호화를 사용하여 암호 저장"
    진단결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "해독 가능한 암호화를 사용하여 암호 저장 방지"
}

# Check for Administrator permissions
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "관리자 권한이 필요합니다..."
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $args"
    Start-Process PowerShell -ArgumentList $arguments -Verb RunAs
    Exit
}

# Set the console code page and color
[Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding(437)
$host.UI.RawUI.BackgroundColor = 'DarkGreen'
$host.UI.RawUI.ForegroundColor = 'Green'
Clear-Host

# Initial setup
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null
New-Item -Path "$rawDir\compare.txt" -ItemType File

# Capture the installation path
$installPath = Get-Location
$installPath | Out-File -FilePath "$rawDir\install_path.txt"

# Collect system information
systeminfo | Out-File -FilePath "$rawDir\systeminfo.txt"

# IIS Configuration
$applicationHostConfig = Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig | Out-File -FilePath "$rawDir\iis_setting.txt"
(Get-Content "$env:WINDOWS\system32\inetsrv\MetaBase.xml") -join "`n" | Out-File -FilePath "$rawDir\iis_setting.txt" -Append

# Check "Store passwords using reversible encryption" policy
$localSecurityPolicy = Get-Content "$rawDir\Local_Security_Policy.txt"
$clearTextPasswordSetting = $localSecurityPolicy | Where-Object { $_ -match "ClearTextPassword" }

# "Store passwords using reversible encryption" 정책 검사 후 JSON 객체 업데이트
If ($clearTextPasswordSetting -match "0") {
    $json.현황 += "가역 암호화를 사용하여 비밀번호 저장 정책이 '사용 안 함'으로 설정되어 있습니다."
} Else {
    $json.진단결과 = "취약"
    $json.현황 += "가역 암호화를 사용하여 비밀번호 저장 정책이 적절히 구성되지 않았습니다."
}

# JSON 결과를 파일로 저장
$jsonFilePath = "$resultDir\W-Window-${computerName}-diagnostic_result.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
