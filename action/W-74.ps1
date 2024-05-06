# 진단 결과를 위한 JSON 객체 초기화
$json = @{
    Category = "보안 관리"
    Code = "W-74"
    RiskLevel = "높음"
    DiagnosticItem = "세션 연결 해제 전 필요한 유휴 시간"
    DiagnosticResult = "양호"  # 기본값으로 '양호' 가정
    Status = @()
    Countermeasure = "세션 연결 해제 전 필요한 유휴 시간 설정 조정"
}

# 관리자 권한이 없는 경우 관리자 권한 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File `"$PSCommandPath`"", "-Verb", "RunAs"
    Exit
}

# 환경 및 디렉토리 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 기존 데이터 삭제 및 새 감사 데이터를 위한 디렉토리 생성
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# 로컬 보안 정책을 파일로 내보내기
secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null

# 강제 로그오프 및 자동 연결 해제에 대한 LanManServer 매개변수 설정 검사
$lanManServerParams = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanManServer\Parameters"
$enableForcedLogOff = $lanManServerParams.EnableForcedLogOff
$autoDisconnect = $lanManServerParams.AutoDisconnect

if ($enableForcedLogOff -eq 1 -and $autoDisconnect -eq 15) {
    $json.Status += "강제 로그오프 및 자동 연결 해제 서버 설정이 적절하게 구성되었습니다."
} else {
    $json.DiagnosticResult = "취약"
    $json.Status += "강제 로그오프 및 자동 연결 해제 서버 설정이 적절하게 구성되지 않았습니다."
}

# JSON 결과를 파일로 저장
$jsonFilePath = "$resultDir\W-74.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# 정리
Remove-Item "$rawDir\*" -Force

Write-Host "스크립트가 성공적으로 완료되었습니다."
