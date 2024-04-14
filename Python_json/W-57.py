# JSON 데이터 초기화
$json = @{
    분류 = "로그관리"
    코드 = "W-57"
    위험도 = "상"
    진단 항목 = "정책에 따른 시스템 로깅 설정"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "정책에 따른 시스템 로깅 설정"
}

# 관리자 권한 확인 및 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"' -Verb RunAs"
    exit
}

# 환경 설정 및 디렉터리 준비
$OutputEncoding = [System.Text.Encoding]::GetEncoding(437)
$Host.UI.RawUI.ForegroundColor = "Green"
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDir, $resultDir -Force | Out-Null

# 감사 정책 설정 검사
$securitySettings = Get-Content "$rawDir\Local_Security_Policy.txt"
$auditSettings = @("AuditLogonEvents", "AuditPrivilegeUse", "AuditPolicyChange", "AuditDSAccess", "AuditAccountLogon", "AuditAccountManage")
$incorrectlyConfigured = $false

foreach ($setting in $auditSettings) {
    if ($securitySettings -match "$setting.*0") {
        $incorrectlyConfigured = $true
        $json.현황 += "$setting: No Auditing"
    }
}

if ($incorrectlyConfigured) {
    $json.진단 결과 = "취약"
} else {
    $json.현황 += "All audit events are correctly configured."
}

# JSON 데이터를 파일로 저장
$jsonPath = "$resultDir\W-57_${computerName}_diagnostic_results.json"
$json | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# 결과 요약 및 저장
Get-Content "$resultDir\W-57_${computerName}_diagnostic_results.json" | Out-File "$resultDir\security_audit_summary.txt"

Write-Host "Results have been saved to $resultDir\security_audit_summary.txt."

# 정리 작업
Remove-Item "$rawDir\*" -Force

Write-Host "Script has completed."
