# JSON 데이터 초기화
$json = @{
    분류 = "계정관리"
    코드 = "W-48"
    위험도 = "상"
    진단 항목 = "SNMP Access control 설정"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "SNMP Access control 설정"
}

# 관리자 권한 확인 및 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", $PSCommandPath, "-Verb", "RunAs"
    Exit
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

# SNMP 허용된 관리자 설정 검사
Write-Host "------------------------------------------W-48 SNMP 허용된 관리자 설정 검사------------------------------------------"
$snmpService = Get-Service -Name SNMP -ErrorAction SilentlyContinue
if ($snmpService.Status -eq "Running") {
    $permittedManagers = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers" -ErrorAction SilentlyContinue
    if ($permittedManagers -and $permittedManagers.PSObject.Properties.Value) {
        $json.진단 결과 = "양호"
        $json.현황 += "SNMP 서비스가 실행 중이며 허용된 관리자가 구성되어 있습니다. 해당 설정은 네트워크 보안을 강화하는 데 도움이 됩니다."
    } else {
        $json.진단 결과 = "경고"
        $json.현황 += "SNMP 서비스가 실행 중이지만 허용된 관리자가 명확하게 구성되지 않았습니다. SNMP 관리를 위한 보안 조치로 허용된 관리자를 명확하게 설정하는 것이 권장됩니다."
    }
} else {
    $json.현황 += "SNMP 서비스가 실행되지 않고 있습니다."
}
Write-Host "-------------------------------------------진단 종료------------------------------------------"

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-48.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# 결과 요약
Write-Host "결과 요약이 $jsonFilePath에 저장되었습니다."  # Corrected the summary path

# 정리 작업
Write-Host "정리 작업을 수행합니다..."
Remove-Item "$rawDir\*" -Force

Write-Host "스크립트를 종료합니다."
