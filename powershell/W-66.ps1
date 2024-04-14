# JSON 데이터 초기화
$json = @{
    분류 = "보안관리"
    코드 = "W-66"
    위험도 = "상"
    진단 항목 = "원격 시스템에서 강제로 시스템 종료"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "원격 시스템에서 강제로 시스템 종료 정책을 적절히 설정"
}

# 관리자 권한 확인 및 요청
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process PowerShell -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "$PSCommandPath" -Verb RunAs
    exit
}

# 환경 설정 및 초기 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDir, $resultDir | Out-Null

# "원격 시스템 종료" 권한 검사
$securityPolicy = Get-Content "$rawDir\Local_Security_Policy.txt"
$remoteShutdownPrivilege = $securityPolicy | Where-Object {$_ -match "SeRemoteShutdownPrivilege"}

if ($remoteShutdownPrivilege -match ",\*S-1-5-32-544" -or $remoteShutdownPrivilege -match "\*S-1-5-32-544,") {
    $json.진단 결과 = "취약"
    $json.현황 += "원격에서 시스템 종료 권한이 Administrators 그룹에만 부여되어 있습니다."
} else {
    $json.현황 += "원격에서 시스템 종료 권한이 안전하게 설정되어 있습니다."
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-66.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# 결과 요약 및 출력
Get-Content -Path "$resultDir\W-66_${computerName}_diagnostic_results.json" | Out-File -FilePath "$resultDir\security_audit_summary.txt"
Write-Host "결과가 $resultDir\security_audit_summary.txt에 저장되었습니다."

# 정리 작업 및 스크립트 종료 메시지
Remove-Item "$rawDir\*" -Force
Write-Host "스크립트를 종료합니다."
