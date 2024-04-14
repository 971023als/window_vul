$json = @{
    "분류" = "보안관리"
    "코드" = "W-82"
    "위험도" = "상"
    "진단 항목" = "Windows 인증 모드 사용"
    "진단 결과" = "양호"
    "현황" = @()
    "대응방안" = "Windows 인증 모드 사용"
}

# Check for administrator privileges
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "$PSCommandPath", "-Verb", "RunAs"
    exit
}

$computerName = $env:COMPUTERNAME
$resultDir = "C:\Window_${computerName}_result"

# Ensure the result directory exists
if (-not (Test-Path $resultDir)) {
    New-Item -Path $resultDir -ItemType Directory -Force | Out-Null
}

# SQL Server authentication mode check
try {
    $sqlServerInstance = "SQLServerName"  # Replace with your actual SQL Server instance name
    $sqlNamespace = "ROOT\Microsoft\SqlServer\ComputerManagement" + ((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server").InstalledInstances | ForEach-Object { $_.Substring($_.length - 2, 2) })
    $authModeQuery = "SELECT * FROM SqlServiceAdvancedProperty WHERE SQLServiceType = 1 AND PropertyName = 'IsIntegratedSecurityOnly'"
    $authMode = Get-WmiObject -Query $authModeQuery -Namespace $sqlNamespace | Select-Object -ExpandProperty PropertyValue

    $message = if ($authMode -eq 1) {
        "Windows 인증 모드가 활성화되어 있습니다."
    } else {
        "Windows 인증 모드가 비활성화되어 있습니다. 혼합 모드 인증이 사용 중입니다."
    }
    $message | Out-File "$resultDir\W-82-${computerName}-result.txt"
} catch {
    "SQL Server 인증 모드 설정을 확인하는 중 오류 발생: $_" | Out-File "$resultDir\W-82-${computerName}-result.txt"
}

# Save JSON results
$jsonFilePath = "$resultDir\W-82.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath

Write-Host "스크립트 실행 완료. 결과는 $resultDir 에 저장되었습니다."
