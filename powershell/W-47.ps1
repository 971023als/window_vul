# JSON 데이터 초기화
$json = @{
    분류 = "서비스관리"
    코드 = "W-47"
    위험도 = "상"
    진단 항목 = "SNMP 서비스 커뮤니티스트링의 복잡성 설정"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "SNMP 서비스 커뮤니티스트링의 복잡성 설정"
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

# SNMP 서비스 커뮤니티 스트링 검사
Write-Host "------------------------------------------W-47 SNMP 서비스 커뮤니티 스트링 검사------------------------------------------"
$snmpService = Get-Service -Name SNMP -ErrorAction SilentlyContinue
if ($snmpService.Status -eq "Running") {
    $communities = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities"
    if ($communities -and ($communities.PSObject.Properties.Name -contains "public" -or $communities.PSObject.Properties.Name -contains "private")) {
        $json.진단 결과 = "경고"
        $json.현황 += "SNMP 서비스가 실행 중이며 기본 커뮤니티 스트링인 'public' 또는 'private'를 사용하고 있습니다. 이는 네트워크에 보안 취약점을 노출시킬 수 있습니다."
    } else {
        $json.현황 += "SNMP 서비스가 실행 중이지만, 'public' 또는 'private'와 같은 기본 커뮤니티 스트링을 사용하고 있지 않습니다."
    }
} else {
    $json.현황 += "SNMP 서비스가 실행되지 않고 있습니다."
}
Write-Host "-------------------------------------------진단 종료------------------------------------------"

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-47.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# 결과 요약
Write-Host "결과 요약이 $resultDir\security_audit_summary.txt에 저장되었습니다."
Get-Content "$resultDir\W-47_${computerName}_diagnostic_results.json" | Out-File "$resultDir\security_audit_summary.txt"

# 정리 작업
Write-Host "정리 작업을 수행합니다..."
Remove-Item "$rawDir\*" -Force

Write-Host "스크립트를 종료합니다."
