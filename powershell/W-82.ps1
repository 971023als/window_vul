$json = @{
    "분류" = "보안관리"
    "코드" = "W-82"
    "위험도" = "상"
    "진단 항목" = "Windows 인증 모드 사용"
    "진단 결과" = "양호"  # 기본 값을 "양호"로 가정
    "현황" = @()
    "대응방안" = "Windows 인증 모드 사용"
}

# 관리자 권한 확인 및 스크립트 초기 설정
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "$PSCommandPath", "-Verb", "RunAs"
    exit
}

$computerName = $env:COMPUTERNAME
$resultDir = "C:\Window_${computerName}_result"

# 결과 디렉터리 생성
if (-not (Test-Path $resultDir)) {
    New-Item -Path $resultDir -ItemType Directory -Force | Out-Null
}

# SQL Server 인증 모드 설정 검사
try {
    $sqlServerInstance = "SQLServerName"  # SQL 서버 인스턴스 이름을 적절히 설정하세요.
    $authMode = (Get-WmiObject -Query "SELECT * FROM SqlServiceAdvancedProperty WHERE SQLServiceType = 1 AND PropertyName = 'IsIntegratedSecurityOnly'" -Namespace "ROOT\Microsoft\SqlServer\ComputerManagement14").PropertyValue
    $message = if ($authMode -eq 1) {
        "W-82: Windows 인증 모드가 활성화되어 있습니다."
    } else {
        "W-82: Windows 인증 모드가 비활성화되어 있습니다. 혼합 모드 인증이 사용 중입니다."
    }
    "$message" | Out-File "$resultDir\W-82-${computerName}-result.txt"
} catch {
    "W-82: SQL Server 인증 모드 설정을 확인하는 중 오류 발생." | Out-File "$resultDir\W-82-${computerName}-result.txt"
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-82.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath

# 스크립트 종료 전 임시 파일 삭제
# 이 경우에는 임시 파일을 사용하지 않으므로 해당 코드는 삭제합니다.

Write-Host "스크립트 실행 완료"
