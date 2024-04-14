# Define audit parameters in a hashtable for easy reference and update
$auditParams = @{
    Category = "Account Management"
    Code = "W-34"
    RiskLevel = "High"
    AuditItem = "Use of decryptable encryption for password storage"
    AuditResult = "Good"  # Assuming good as the default state
    CurrentStatus = @()
    Mitigation = "Use of non-decryptable encryption for password storage"
}

# Request Administrator privileges if not already running with them
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "`"$PSCommandPath`"", "-Verb", "RunAs"
    exit
}

$computerName = $env:COMPUTERNAME
$dirs = @{
    Raw = "C:\Window_${computerName}_raw"
    Result = "C:\Window_${computerName}_result"
}

# 환경 설정
function Initialize-Environment {
    chcp 437 | Out-Null
    $host.UI.RawUI.BackgroundColor = "DarkGreen"
    $host.UI.RawUI.ForegroundColor = "Green"
    Clear-Host

    Write-Host "환경을 설정하고 있습니다..."
    Remove-Item -Path $dirs.Raw, $dirs.Result -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -Path $dirs.Raw, $dirs.Result -ItemType Directory | Out-Null

    secedit /export /cfg "$($dirs.Raw)\Local_Security_Policy.txt" | Out-Null
    New-Item -Path "$($dirs.Raw)\compare.txt" -ItemType File | Out-Null

    systeminfo | Out-File -FilePath "$($dirs.Raw)\systeminfo.txt"
}

# IIS 구성 분석
function Analyze-IISConfiguration {
    Write-Host "IIS 설정을 분석하고 있습니다..."
    $applicationHostConfig = Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
    $applicationHostConfig | Out-File -FilePath "$($dirs.Raw)\iis_setting.txt"

    if ($applicationHostConfig -match "IIS5") {
        $auditParams.CurrentStatus += "사용되지 않는 IIS 버전이 감지되었습니다. 업그레이드가 필요합니다."
        $auditParams.AuditResult = "취약"
    } else {
        $auditParams.CurrentStatus += "사용되지 않는 IIS 버전이 감지되지 않았습니다. 보안 표준을 준수하고 있습니다."
    }
}

# 스크립트 단계 실행
Initialize-Environment
Analyze-IISConfiguration

# JSON 결과 파일 저장
$jsonFilePath = "$($dirs.Result)\W-34.json"
$auditParams | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
