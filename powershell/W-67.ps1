# JSON 데이터 초기화
$json = @{
    분류 = "보안관리"
    코드 = "W-67"
    위험도 = "상"
    진단 항목 = "보안 감사를 로그할 수 없는 경우 즉시 시스템 종료"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "보안 감사를 로그할 수 없는 경우 즉시 시스템 종료 정책을 적절히 설정"
}

# 관리자 권한 확인
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "$PSCommandPath" -Verb RunAs
    exit
}

# 초기 설정 및 디렉터리 생성
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDir, $resultDir | Out-Null

# 감사 실패 시 시스템 충돌 설정 확인
$policyValue = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "CrashOnAuditFail"

if ($policyValue.CrashOnAuditFail -eq 0) {
    $json.현황 += "감사 실패 시 시스템 충돌 설정[CrashOnAuditFail]이 보안에 적합하게 설정되었습니다."
} else {
    $json.진단 결과 = "취약"
    $json.현황 += "감사 실패 시 시스템 충돌 설정[CrashOnAuditFail]이 보안 요구사항에 맞게 설정되지 않았습니다."
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-67.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# 결과 요약 및 출력
Get-Content -Path "$resultDir\W-67_${computerName}_diagnostic_results.json" | Out-File -FilePath "$resultDir\security_audit_summary.txt"
Write-Host "결과가 $resultDir\security_audit_summary.txt 에 저장되었습니다."

# 정리 작업 및 스크립트 종료
Remove-Item -Path "$rawDir\*" -Force
Write-Host "스크립트를 종료합니다."
