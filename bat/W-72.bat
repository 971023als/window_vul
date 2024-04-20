# JSON 데이터 초기화
$json = @{
    Category = "보안 관리"
    Code = "W-72"
    RiskLevel = "높음"
    DiagnosticItem = "DOS 공격 방어 레지스트리 설정"
    DiagnosticResult = "양호"  # 기본값으로 '양호' 가정
    Status = @()
    Countermeasure = "DOS 공격 방어를 위한 레지스트리 설정 조정"
}

# 관리자 권한 확인 및 요청
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "$PSCommandPath", "-Verb", "RunAs"
    exit
}

# 환경 설정 및 디렉토리 준비
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

Remove-Item -Path $rawDir, $resultDir -Recurse -Force
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# W-72 확인: DOS 공격 방어 관련 레지스트리 설정
# 예시: SynAttackProtect 레지스트리 키 확인
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
$synAttackProtect = Get-ItemProperty -Path $regPath -Name "SynAttackProtect" -ErrorAction SilentlyContinue

if ($synAttackProtect -and $synAttackProtect.SynAttackProtect -eq 1) {
    $json.Status += "SynAttackProtect가 활성화되어 DOS 공격 방어가 강화되었습니다."
} else {
    $json.DiagnosticResult = "취약"
    $json.Status += "SynAttackProtect가 비활성화되었거나 올바르게 구성되지 않았습니다."
}

# JSON 결과를 파일로 저장
$jsonFilePath = "$resultDir\W-72.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# 결과 요약 및 스크립트 완료
Get-Content -Path "$resultDir\W-72_${computerName}_diagnostic_results.json" | Out-File -FilePath "$resultDir\security_audit_summary.txt"
Write-Host "$resultDir\security_audit_summary.txt 에 결과가 저장되었습니다."

# 정리 및 스크립트 종료
Remove-Item -Path "$rawDir\*" -Force
Write-Host "스크립트가 완료되었습니다."
