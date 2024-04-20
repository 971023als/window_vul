# Define the audit configuration
$auditConfig = @{
    Category    = "Account Management"
    Code        = "W-37"
    RiskLevel   = "High"
    AuditItem   = "Use of decryptable encryption for password storage"
    AuditResult = "Good"  # Default value
    Status      = @()
    Recommendation = "Use of non-decryptable encryption for password storage"
}

# Request Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", $PSCommandPath, "-Verb", "RunAs"
    Exit
}

# 콘솔 환경 설정
function Initialize-Environment {
    chcp 437 | Out-Null
    $host.UI.RawUI.BackgroundColor = "DarkGreen"
    $host.UI.RawUI.ForegroundColor = "Green"
    Clear-Host
    Write-Host "환경을 초기화 중입니다..."
}

# 디렉터리 설정 및 정리
function Setup-Directories {
    $global:computerName = $env:COMPUTERNAME
    $global:rawDir = "C:\Audit_${computerName}_Raw"
    $global:resultDir = "C:\Audit_${computerName}_Results"

    Remove-Item $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item $rawDir, $resultDir -ItemType Directory | Out-Null
    Write-Host "디렉터리 설정 완료."
}

# 로컬 보안 정책 내보내기 및 시스템 정보 수집
function Export-PolicyAndCollect-Info {
    secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null
    systeminfo | Out-File "$rawDir\SystemInfo.txt"
    Write-Host "로컬 보안 정책을 내보내고 시스템 정보를 수집했습니다."
}

# Microsoft FTP 서비스 감사
function Audit-FTPServices {
    Write-Host "Microsoft FTP 서비스를 감사 중입니다..."
    $ftpService = Get-Service -Name "MSFTPSVC" -ErrorAction SilentlyContinue
    if ($ftpService -and $ftpService.Status -eq "Running") {
        "W-37, 경고, | Microsoft FTP 서비스가 실행 중이며, 이는 취약점이 될 수 있습니다." | Out-File "$resultDir\W-Window-${computerName}-Result.txt"
        Write-Host "경고: Microsoft FTP 서비스가 실행 중입니다. 필요하지 않은 경우 비활성화를 고려하세요."
    } else {
        "W-37, 안전, | Microsoft FTP 서비스가 실행되지 않고 있습니다. 조치가 필요 없습니다." | Out-File "$resultDir\W-Window-${computerName}-Result.txt"
        Write-Host "안전: Microsoft FTP 서비스가 실행되지 않고 있습니다."
    }
}

# 주 실행 흐름
Initialize-Environment
Setup-Directories
Export-PolicyAndCollect-Info
Audit-FTPServices

# JSON 결과 파일 저장
$jsonFilePath = "$resultDir\W-37.json"
$auditConfig | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
