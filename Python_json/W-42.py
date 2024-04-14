# JSON 데이터 구조 정의
$json = @{
    분류 = "계정관리"
    코드 = "W-42"
    위험도 = "상"
    진단항목 = "RDS(RemoteDataServices)제거"
    진단결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "RDS(RemoteDataServices)제거"
}

# 관리자 권한 요청
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $script = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $args"
    Start-Process PowerShell -ArgumentList $script -Verb RunAs
    exit
}

# 콘솔 환경 설정
chcp 437 | Out-Null
$host.UI.RawUI.BackgroundColor = "DarkGreen"
$host.UI.RawUI.ForegroundColor = "Green"
Clear-Host

Write-Host "------------------------------------------설정 시작---------------------------------------"
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 이전 디렉토리 삭제 및 새 디렉토리 생성
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# W-42 RDS 상태 점검 시작
Write-Host "------------------------------------------W-42 RDS 상태 점검 시작------------------------------------------"
$webService = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue

if ($webService.Status -eq "Running") {
    $json.진단결과 = "위험"
    $json.현황 += "웹 서비스가 실행 중입니다. RDS(Remote Data Services)가 활성화되어 있을 수 있습니다."
    $json.대응방안 = "웹 서비스를 비활성화하거나 RDS 관련 구성을 제거하세요."
} else {
    $json.현황 += "웹 서비스가 실행되지 않거나 설치되지 않았습니다. RDS 제거 상태가 양호합니다."
}

# 결과를 JSON 파일로 저장
$jsonFilePath = "$resultDir\W-42_diagnostics_results.json"
$json | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonFilePath

Write-Host "-------------------------------------------W-42 RDS 상태 점검 종료------------------------------------------"

# 결과 요약
Write-Host "결과가 $jsonFilePath 에 저장되었습니다."

# 정리 작업
Write-Host "정리 작업을 수행합니다..."
Remove-Item "$rawDir\*" -Force

Write-Host "스크립트를 종료합니다."
