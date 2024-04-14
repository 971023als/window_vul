# JSON 데이터 초기화
$json = @{
    Category = "보안 관리"
    Code = "W-71"
    RiskLevel = "높음"
    DiagnosticItem = "디스크 볼륨 암호화 설정"
    DiagnosticResult = "양호"  # 기본값으로 '양호' 가정
    Status = @()
    Countermeasure = "디스크 볼륨 암호화 설정을 통한 데이터 보호 강화"
}

# 관리자 권한 확인 및 요청
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "$($MyInvocation.MyCommand.Definition)" -Verb RunAs
    exit
}

$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 이전 데이터 삭제 및 디렉토리 생성
Remove-Item -Path $rawDir, $resultDir -Recurse -Force
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# 디스크 볼륨 암호화 설정 확인
# 예시: BitLocker 상태 확인 (환경에 맞게 조정)
try {
    $bitLockerStatus = Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop | Select-Object -ExpandProperty ProtectionStatus

    if ($bitLockerStatus -eq 1) {
        $json.Status += "C: 드라이브는 BitLocker로 암호화되었습니다."
    } else {
        $json.DiagnosticResult = "취약"
        $json.Status += "C: 드라이브는 BitLocker로 암호화되지 않았습니다."
    }
} catch {
    $json.DiagnosticResult = "오류"
    $json.Status += "BitLocker 상태를 검색하지 못했습니다. 이 시스템에 BitLocker가 없을 수 있습니다."
}

# JSON 결과를 파일로 저장
$jsonFilePath = "$resultDir\W-71.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# 결과 요약 및 출력
Get-Content -Path "$resultDir\W-71_${computerName}_diagnostic_results.json" | Out-File -FilePath "$resultDir\security_audit_summary.txt"
Write-Host "$resultDir\security_audit_summary.txt 에 결과가 저장되었습니다."

# 정리 및 스크립트 완료 메시지
Remove-Item "$rawDir\*" -Force
Write-Host "스크립트가 완료되었습니다."
