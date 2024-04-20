# JSON 데이터 초기화
$json = @{
    분류 = "서비스관리"
    코드 = "W-46"
    위험도 = "상"
    진단 항목 = "SNMP 서비스 구동 점검"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "SNMP 서비스 구동 점검"
}

# 관리자 권한 요청
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process PowerShell -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", $PSCommandPath, "-Verb", "RunAs"
    exit
}

# 콘솔 환경 설정
chcp 437 | Out-Null
$host.UI.RawUI.BackgroundColor = "DarkGreen"
$host.UI.RawUI.ForegroundColor = "Green"
Clear-Host

Write-Host "------------------------------------------설정 시작---------------------------------------"
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 이전 디렉토리 삭제 및 새 디렉토리 생성
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# SNMP 서비스 상태 검사
Write-Host "------------------------------------------W-46 SNMP 서비스 상태 검사 시작------------------------------------------"
$snmpService = Get-Service -Name "SNMP" -ErrorAction SilentlyContinue
if ($snmpService -and $snmpService.Status -eq "Running") {
    $json.진단 결과 = "경고"
    $json.현황 += "SNMP 서비스가 활성화되어 있습니다. 이는 보안상 위험할 수 있으므로, 필요하지 않은 경우 비활성화하는 것이 권장됩니다."
} else {
    $json.현황 += "SNMP 서비스가 실행되지 않고 있습니다. 이는 추가 보안을 위한 긍정적인 상태입니다."
}
Write-Host "-------------------------------------------W-46 SNMP 서비스 상태 검사 종료------------------------------------------"

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-46.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# 정리 작업
Write-Host "정리 작업을 수행합니다..."
Remove-Item "$rawDir\*" -Force

Write-Host "스크립트를 종료합니다."
