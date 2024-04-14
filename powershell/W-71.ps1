# JSON 데이터 초기화
$json = @{
    분류 = "보안관리"
    코드 = "W-71"
    위험도 = "상"
    진단 항목 = "디스크볼륨 암호화 설정"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "디스크볼륨 암호화 설정을 통한 데이터 보호 강화"
}

# 관리자 권한 요청 및 환경 설정
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "Start-Process PowerShell -ArgumentList '-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`"' -Verb RunAs" -Verb RunAs
    exit
}

$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 기존 데이터 삭제 및 디렉터리 생성
Remove-Item -Path $rawDir, $resultDir -Recurse -Force
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# 디스크볼륨 암호화 설정 검사
# 예시: BitLocker 사용 여부 확인 (실제 환경에 맞게 조정 필요)
$bitLockerStatus = Get-BitLockerVolume -MountPoint "C:" | Select-Object -ExpandProperty ProtectionStatus

if ($bitLockerStatus -eq 1) {
    $json.현황 += "C 드라이브가 BitLocker로 암호화되어 있습니다."
} else {
    $json.진단 결과 = "취약"
    $json.현황 += "C 드라이브가 BitLocker로 암호화되어 있지 않습니다."
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-71.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# 결과 요약 및 출력
Get-Content -Path "$resultDir\W-71_${computerName}_diagnostic_results.json" | Out-File -FilePath "$resultDir\security_audit_summary.txt"
Write-Host "결과가 $resultDir\security_audit_summary.txt에 저장되었습니다."

# 정리 작업 및 스크립트 종료
Remove-Item "$rawDir\*" -Force
Write-Host "스크립트를 종료합니다."
