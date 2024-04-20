# JSON 데이터 구조 초기화
$json = @{
    Category = "보안 관리"
    Code = "W-67"
    RiskLevel = "높음"
    DiagnosticItem = "보안 감사를 기록할 수 없는 경우 시스템 즉시 종료"
    DiagnosticResult = "양호"  # 기본값으로 '양호' 가정
    Status = @()
    Countermeasure = "보안 감사를 기록할 수 없는 경우 시스템을 종료하도록 정책을 적절하게 구성"
}

# 관리자 권한 요청 및 확인
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 환경 및 디렉토리 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDir, $resultDir -Force | Out-Null

# 감사 실패 처리 정책 확인
try {
    $policyValue = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "CrashOnAuditFail"
    if ($policyValue.CrashOnAuditFail -eq 1) {
        $json.DiagnosticResult = "양호"
        $json.Status += "보안 감사를 기록할 수 없는 경우 시스템을 종료하도록 구성되어 보안이 강화되었습니다."
    } else {
        $json.DiagnosticResult = "취약"
        $json.Status += "보안 감사를 기록할 수 없는 경우 시스템이 종료되지 않도록 구성되어 있어 보안 위험이 있을 수 있습니다."
    }
} catch {
    $json.DiagnosticResult = "오류"
    $json.Status += "감사 실패 처리 정책 설정을 검색하는 데 실패했습니다."
}

# JSON 결과를 파일로 저장
$jsonFilePath = "$resultDir\W-67.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# 정리 및 스크립트 종료
Remove-Item -Path "$rawDir\*" -Force
Write-Host "스크립트가 완료되었습니다. 결과가 $resultDir 에 저장되었습니다."
