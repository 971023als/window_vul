# JSON 데이터 초기화
$json = @{
    분류 = "보안관리"
    코드 = "W-65"
    위험도 = "상"
    진단 항목 = "로그온하지 않고 시스템 종료 허용"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "정책 조정을 통해 로그온하지 않고 시스템 종료를 허용하거나 차단"
}

# 관리자 권한 확인 및 요청
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$windowsPrincipal = New-Object Security.Principal.WindowsPrincipal($currentUser)
if (-not $windowsPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "$PSCommandPath" -Verb RunAs
    exit
}

# 환경 변수 설정 및 결과 디렉터리 생성
$computerName = $env:COMPUTERNAME
$resultDir = "C:\Window_${computerName}_result"

if (Test-Path $resultDir) {
    Remove-Item -Path $resultDir -Recurse
}
New-Item -ItemType Directory -Path $resultDir | Out-Null

# "로그온 없이 시스템 종료" 정책 확인
$shutdownWithoutLogon = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System").ShutdownWithoutLogon

# 결과 기록 및 JSON 업데이트
if ($shutdownWithoutLogon -eq 0) {
    $json.진단 결과 = "취약"
    $json.현황 += "취약: '로그온 없이 시스템을 종료할 수 있는 정책'이 비활성화되어 있습니다."
} else {
    $json.현황 += "안전: '로그온 없이 시스템을 종료할 수 있는 정책'이 활성화되어 있습니다."
}

# JSON 데이터를 파일로 저장
$jsonPath = "$resultDir\W-65_${computerName}_diagnostic_results.json"
$json | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# 결과 요약 보고 및 스크립트 종료 메시지
Write-Host "결과가 $resultDir에 저장되었습니다."
Write-Host "스크립트를 종료합니다."
