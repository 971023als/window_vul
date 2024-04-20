# Initialize audit parameters
$auditParameters = @{
    Category = "Account Management"
    Code = "W-35"
    RiskLevel = "High"
    AuditItem = "Use of decryptable encryption for password storage"
    AuditResult = "Good"  # Assuming "Good" as the default state
    CurrentStatus = @()
    MitigationRecommendation = "Use of non-decryptable encryption for password storage"
}

# Request Administrator privileges if not already running with them
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", $PSCommandPath, "-Verb", "RunAs"
    exit
}

# 콘솔 환경 설정
function Initialize-Console {
    chcp 437 | Out-Null
    $host.UI.RawUI.BackgroundColor = "DarkGreen"
    $host.UI.RawUI.ForegroundColor = "Green"
    Clear-Host
    Write-Host "환경을 설정하고 있습니다..."
}

# 감사 환경 준비
function Setup-AuditEnvironment {
    $global:computerName = $env:COMPUTERNAME
    $global:rawDir = "C:\Audit_${computerName}_RawData"
    $global:resultDir = "C:\Audit_${computerName}_Results"

    # 이전 데이터 정리 및 새 디렉터리 준비
    Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

    # 로컬 보안 정책 및 시스템 정보 내보내기
    secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null
    systeminfo | Out-File "$rawDir\SystemInfo.txt"
}

# WebDAV 보안 감사 수행
function Perform-WebDAVSecurityCheck {
    Write-Host "WebDAV 보안 검사를 수행하고 있습니다..."
    $serviceStatus = (Get-Service W3SVC -ErrorAction SilentlyContinue).Status

    if ($serviceStatus -eq "Running") {
        $webDavConfigurations = Select-String -Path "$env:SystemRoot\System32\inetsrv\config\applicationHost.config" -Pattern "webdav" -AllMatches

        if ($webDavConfigurations) {
            foreach ($config in $webDavConfigurations) {
                $config.Line | Out-File -FilePath "$rawDir\WebDAVConfigDetails.txt" -Append
            }
            Write-Host "검토 필요: WebDAV 구성이 발견되었습니다. 자세한 내용은 WebDAVConfigDetails.txt 파일을 참조하세요."
        } else {
            Write-Host "조치 필요 없음: WebDAV가 적절하게 구성되었거나 존재하지 않습니다."
        }
    } else {
        Write-Host "조치 필요 없음: IIS 웹 게시 서비스가 실행 중이지 않습니다."
    }
}

# 주 스크립트 실행
Initialize-Console
Setup-AuditEnvironment
Perform-WebDAVSecurityCheck

# JSON 결과 파일 저장
$jsonFilePath = "$resultDir\W-35.json"
$auditParameters | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
