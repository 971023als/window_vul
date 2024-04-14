# JSON 데이터 초기화
$json = @{
    Category = "보안 관리"
    Code = "W-70"
    RiskLevel = "높음"
    DiagnosticItem = "이동식 미디어 포맷 및 추출 허용"
    DiagnosticResult = "양호"  # 기본값으로 '양호' 가정
    Status = @()
    Countermeasure = "이동식 미디어 포맷 및 추출에 대한 적절한 제어"
}

# 관리자 권한 확인 및 요청
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 환경 설정 및 디렉토리 생성
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDir, $resultDir -Force | Out-Null

# 로컬 보안 정책 내보내기 및 분석
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
$localSecurityPolicy = Get-Content "$rawDir\Local_Security_Policy.txt"
$allocateDASD = $localSecurityPolicy | Where-Object { $_ -match "AllocateDASD" -and $_ -notmatch "0" }

# 분석 결과에 따라 JSON 업데이트
if ($allocateDASD) {
    $json.Status += "디스크 할당 권한 변경은 관리자만 제한적으로 변경할 수 있습니다."
} else {
    $json.DiagnosticResult = "취약"
    $json.Status += "디스크 할당 권한 변경이 관리자만으로 제한되지 않습니다."
}

# JSON 결과를 파일로 저장
$jsonFilePath = "$resultDir\W-70.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# 결과 요약 및 저장
Get-Content -Path "$resultDir\W-70_${computerName}_diagnostic_results.json" | Out-File -FilePath "$resultDir\security_audit_summary.txt"
Write-Host "$resultDir\security_audit_summary.txt 에 결과가 저장되었습니다."

# 정리 및 스크립트 완료 메시지
Remove-Item "$rawDir\*" -Force
Write-Host "스크립트가 완료되었습니다."
