# JSON 데이터 초기화
$json = @{
    분류 = "보안관리"
    코드 = "W-70"
    위험도 = "상"
    진단 항목 = "이동식 미디어 포맷 및 꺼내기 허용"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "이동식 미디어의 포맷 및 꺼내기를 적절히 제어"
}

# 관리자 권한 확인 및 요청
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"" + $myinvocation.MyCommand.Definition + "`" " + $args
    Start-Process "PowerShell" -Verb RunAs -ArgumentList $arguments
    exit
}

# 초기 설정 및 디렉터리 생성
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# 로컬 보안 정책 내보내기 및 분석
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
$localSecurityPolicy = Get-Content "$rawDir\Local_Security_Policy.txt"
$allocateDASD = $localSecurityPolicy | Where-Object { $_ -match "AllocateDASD" -and $_ -match "0" }

# 분석 결과에 따른 JSON 업데이트
if ($allocateDASD) {
    $json.현황 += "디스크 할당 권한 변경이 관리자만 가능하도록 설정되어 있는 상태입니다."
} else {
    $json.진단 결과 = "취약"
    $json.현황 += "디스크 할당 권한 변경이 관리자만 가능하도록 설정되지 않았습니다."
}

# JSON 데이터를 파일로 저장
$jsonPath = "$resultDir\W-70_${computerName}_diagnostic_results.json"
$json | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# 결과 요약 및 출력
Get-Content -Path "$resultDir\W-70_${computerName}_diagnostic_results.json" | Out-File -FilePath "$resultDir\security_audit_summary.txt"
Write-Host "결과가 $resultDir\security_audit_summary.txt에 저장되었습니다."

# 정리 작업 및 스크립트 종료
Remove-Item "$rawDir\*" -Force
Write-Host "스크립트를 종료합니다."
