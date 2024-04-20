# JSON 객체 초기화
$json = @{
    Category = "보안 관리"
    Code = "W-73"
    RiskLevel = "높음"
    DiagnosticItem = "사용자가 프린터 드라이버를 설치하는 것을 방지"
    DiagnosticResult = "양호"  # 기본값으로 '양호' 가정
    Status = @()
    Countermeasure = "사용자가 프린터 드라이버를 설치하지 못하도록 설정 조정"
}

# 관리자 권한 요청
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Verb RunAs"
    exit
}

# 환경 및 디렉토리 구조 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# 로컬 보안 정책 내보내기
secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null

# 프린터 드라이버 설치 권한 검증
$securityPolicy = Get-Content "$rawDir\Local_Security_Policy.txt"
$addPrinterDrivers = $securityPolicy | Where-Object { $_ -match "AddPrinterDrivers" -and $_ -match "= 0" }

if ($addPrinterDrivers) {
    $json.DiagnosticResult = "취약"
    $json.Status += "프린터 드라이버 설치 권한이 적절히 설정되지 않았습니다."
} else {
    $json.Status += "프린터 드라이버 설치 권한이 적절히 설정되었습니다."
}

# JSON 결과 저장
$jsonFilePath = "$resultDir\W-73.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# 정리
Remove-Item "$rawDir\*" -Force -ErrorAction SilentlyContinue

Write-Host "스크립트가 완료되었습니다."
