# JSON 데이터 초기화
$json = @{
    분류 = "보안관리"
    코드 = "W-72"
    위험도 = "상"
    진단 항목 = "Dos공격 방어 레지스트리 설정"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "Dos공격 방어를 위한 레지스트리 설정 조정"
}

# 관리자 권한 요청 및 환경 설정
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"' -Verb RunAs"
    Exit
}

$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 기존 데이터 삭제 및 디렉터리 생성
Remove-Item -Path $rawDir, $resultDir -Recurse -Force
New-Item -Path $rawDir, $resultDir -ItemType Directory

# W-72 검사: Dos공격 방어 관련 레지스트리 설정 검사
# 예시: SynAttackProtect 레지스트리 키 확인
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
$synAttackProtect = Get-ItemProperty -Path $regPath -Name "SynAttackProtect" -ErrorAction SilentlyContinue

if ($synAttackProtect -and $synAttackProtect.SynAttackProtect -eq 1) {
    $json.현황 += "SynAttackProtect가 활성화되어 DoS 공격 방어 설정이 강화되었습니다."
} else {
    $json.진단 결과 = "취약"
    $json.현황 += "SynAttackProtect가 비활성화되어 있거나, 설정이 적절히 조정되지 않았습니다."
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-72.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# 결과 요약 및 출력
Get-Content -Path "$resultDir\W-72_${computerName}_diagnostic_results.json" | Out-File -FilePath "$resultDir\security_audit_summary.txt"
Write-Host "결과가 $resultDir\security_audit_summary.txt에 저장되었습니다."

# 정리 작업 및 스크립트 종료
Remove-Item "$rawDir\*" -Force
Write-Host "스크립트를 종료합니다."
