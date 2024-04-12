$json = @{
    분류 = "계정관리"
    코드 = "W-08"
    위험도 = "상"
    진단항목 = "해독 가능한 암호화를 사용하여 암호 저장"
    진단결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "해독 가능한 암호화를 사용하여 암호 저장"
}

# Check for Administrator privileges
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "관리자 권한이 필요합니다..."
    Start-Process PowerShell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
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

# System Information
systeminfo | Out-File "$rawDir\systeminfo.txt"

# IIS Configuration
$applicationHostConfig = Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig | Out-File "$rawDir\iis_setting.txt"
(Get-Content "$env:WINDOWS\system32\inetsrv\MetaBase.xml") -join "`n" | Out-File "$rawDir\iis_setting.txt" -Append

# Analyze Security Policy
$securityPolicy = Get-Content "$rawDir\Local_Security_Policy.txt"
$lockoutDuration = ($securityPolicy | Where-Object { $_ -match "LockoutDuration" }).Split("=")[1].Trim()
$resetLockoutCount = ($securityPolicy | Where-Object { $_ -match "ResetLockoutCount" }).Split("=")[1].Trim()

# 보안 정책 분석 후 JSON 객체 업데이트
if ($resetLockoutCount -gt 59) {
    if ($lockoutDuration -gt 59) {
        $json.진단결과 = "양호"
        $json.현황 += "정책 충족: '잠금 지속 시간'과 '잠금 카운트 리셋 시간'이 설정 요구사항을 충족합니다."
    } else {
        $json.진단결과 = "취약"
        $json.현황 += "정책 미충족: '잠금 지속 시간' 또는 '잠금 카운트 리셋 시간'이 설정 요구사항을 미충족합니다."
    }
} else {
    $json.진단결과 = "취약"
    $json.현황 += "정책 미충족: '잠금 지속 시간' 또는 '잠금 카운트 리셋 시간'이 설정 요구사항을 미충족합니다."
}

# JSON 결과를 파일로 저장
$jsonFilePath = "$resultDir\W-Window-${computerName}-diagnostic_result.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath