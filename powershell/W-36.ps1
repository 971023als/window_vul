# Define the audit parameters
$auditParams = @{
    Category = "Account Management"
    Code = "W-36"
    RiskLevel = "High"
    AuditItem = "Use of decryptable encryption for password storage"
    AuditResult = "Good"  # Assuming "Good" as the default value
    Status = @()
    Recommendation = "Use of non-decryptable encryption for password storage"
}

# Ensure the script runs with Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", $PSCommandPath, "-Verb", "RunAs"
    exit
}
# 콘솔 환경 설정
function Setup-Console {
    chcp 437 | Out-Null
    $host.UI.RawUI.BackgroundColor = "DarkGreen"
    $host.UI.RawUI.ForegroundColor = "Green"
    Clear-Host
    Write-Host "감사 환경을 초기화 중입니다..."
}

# 감사 환경 설정
function Initialize-AuditEnvironment {
    $global:computerName = $env:COMPUTERNAME
    $global:rawDir = "C:\Audit_${computerName}_Raw"
    $global:resultDir = "C:\Audit_${computerName}_Results"

    # 이전 데이터 정리 및 현재 감사를 위한 디렉터리 설정
    Remove-Item $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item $rawDir, $resultDir -ItemType Directory | Out-Null
    secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null
    systeminfo | Out-File "$rawDir\SystemInfo.txt"
}

# NetBIOS 구성 검사
function Check-NetBIOSConfiguration {
    Write-Host "NetBIOS 구성을 검사 중입니다..."
    $netBIOSConfig = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.TcpipNetbiosOptions -eq 2 }

    if ($netBIOSConfig) {
        "W-36, Good, | NetBIOS over TCP/IP가 비활성화되어 있으며, 보안 구성 권장사항에 부합합니다." | Out-File "$resultDir\W-Window-${computerName}-Result.txt"
        Write-Host "NetBIOS over TCP/IP가 비활성화되어 있습니다 - 구성이 안전합니다."
    } else {
        "W-36, Attention Needed, | 보안 개선을 위해 NetBIOS over TCP/IP 설정을 검토하세요." | Out-File "$resultDir\W-Window-${computerName}-Result.txt"
        Write-Host "주의 필요: NetBIOS over TCP/IP 설정을 검토하세요."
    }
}

# 감사 결과 정리 및 청소
function Finalize-Audit {
    Write-Host "감사 완료. 결과는 $resultDir에서 확인하세요."
    Remove-Item "$rawDir\*" -Force -ErrorAction SilentlyContinue
}

# 주 실행 흐름
Setup-Console
Initialize-AuditEnvironment
Check-NetBIOSConfiguration
Finalize-Audit

# JSON 결과 파일 저장
$jsonFilePath = "$resultDir\W-36.json"
$auditParams | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
