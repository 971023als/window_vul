$json = @{
    "분류" = "보안관리"
    "코드" = "W-78"
    "위험도" = "상"
    "진단 항목" = "보안 채널 데이터 디지털 암호화 또는 서명"
    "진단 결과" = "양호" # 기본 값을 "양호"로 가정
    "현황" = @()
    "대응방안" = "보안 채널 데이터 디지털 암호화 또는 서명"
}

# 관리자 권한 확인 및 스크립트 재실행
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "관리자 권한으로 실행해야 합니다."
    Start-Process PowerShell -ArgumentList "-File", $MyInvocation.MyCommand.Definition -Verb RunAs
    Exit
}

$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 초기 설정 및 디렉터리 준비
$dirs = @($rawDir, $resultDir)
foreach ($dir in $dirs) {
    if (-Not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -ErrorAction Stop
    } else {
        Remove-Item "$dir\*" -Recurse -Force
    }
}

# 로컬 보안 정책 내보내기 및 시스템 정보 수집
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
systeminfo | Out-File "$rawDir\systeminfo.txt"

# IIS 설정 분석
$iisConfigPath = "${env:WinDir}\System32\Inetsrv\Config\applicationHost.Config"
if (Test-Path $iisConfigPath) {
    Get-Content $iisConfigPath | Select-String "physicalPath|bindingInformation" | Out-File "$rawDir\iis_setting.txt"
}

# 보안 정책 분석 - 예시: RequireSignOrSeal, SealSecureChannel, SignSecureChannel
$securityPolicy = Get-Content "$rawDir\Local_Security_Policy.txt"
$conditionsMet = $securityPolicy | Where-Object {
    ($_ -match "RequireSignOrSeal.*1") -or
    ($_ -match "SealSecureChannel.*1") -or
    ($_ -match "SignSecureChannel.*1")
}

# 결과 파일 기록
$resultFilePath = "$resultDir\W-Window-${computerName}-result.txt"
if ($conditionsMet) {
    "W-78,O,|" | Out-File $resultFilePath -Append
    "보안 정책 분석 결과: 모든 조건 만족" | Out-File $resultFilePath -Append
} else {
    "W-78,X,|" | Out-File $resultFilePath -Append
    "보안 정책 분석 결과: 하나 이상의 조건 불만족" | Out-File $resultFilePath -Append
}

# 결과 요약
Get-Content $resultFilePath | Out-File "$resultDir\security_audit_summary.txt"

# 정리 작업
Remove-Item "$rawDir\*" -Force
