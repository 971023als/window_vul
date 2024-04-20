# 변수 초기화
$분류 = "계정 관리"
$코드 = "W-36"
$위험도 = "높음"
$진단_항목 = "비밀번호 저장을 위한 복호화 가능한 암호화 사용"
$진단_결과 = "양호" # "양호"를 기본 값으로 가정
$현황 = @()
$대응방안 = "복호화 불가능한 암호화 방식 사용"

# JSON 키 한국어로 설정
$auditParams = @{
    분류 = $분류
    코드 = $코드
    위험도 = $위험도
    진단_항목 = $진단_항목
    진단_결과 = $진단_결과
    현황 = $현황
    대응방안 = $대응방안
}

# 관리자 권한 확인 및 요청
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

# 감사 환경 초기화
function Initialize-AuditEnvironment {
    $global:computerName = $env:COMPUTERNAME
    $global:rawDir = "C:\Audit_${computerName}_Raw"
    $global:resultDir = "C:\Audit_${computerName}_Results"

    Remove-Item $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item $rawDir, $resultDir -ItemType Directory | Out-Null
    secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null
    systeminfo | Out-File "$rawDir\SystemInfo.txt"
}

# 보안 감사 실행 및 결과 업데이트
function Perform-SecurityAudit {
    Write-Host "보안 감사를 수행 중입니다..."
    # 감사 로직 구현(예: NetBIOS 설정 검사)
    # 이 예에서는 감사 결과를 직접 업데이트
    $auditParams.진단_결과 = "취약" # 감사 후 결과 업데이트
    $auditParams.현황 += "비밀번호 저장에 사용된 암호화가 복호화 가능합니다."
}

# 감사 결과 정리 및 보고
function Finalize-Audit {
    Write-Host "감사 완료. 결과는 $resultDir에서 확인하세요."
    Remove-Item "$rawDir\*" -Force -ErrorAction SilentlyContinue
}

# 스크립트 실행
Setup-Console
Initialize-AuditEnvironment
Perform-SecurityAudit
Finalize-Audit

# JSON 결과 파일 저장
$jsonFilePath = "$resultDir\W-36.json"
$auditParams | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath

Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"
