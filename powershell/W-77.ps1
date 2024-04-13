# JSON 형태로 데이터 저장
security_data = {
    "분류": "보안관리",
    "코드": "W-77",
    "위험도": "상",
    "진단 항목": "LAN Manager 인증 수준",
    "진단 결과": "양호",  # 기본 값을 "양호"로 가정
    "현황": [],
    "대응방안": "LAN Manager 인증 수준 변경"
}

# PowerShell 스크립트

# 관리자 권한으로 실행되지 않았다면 스크립트를 관리자 권한으로 다시 실행
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Start-Process powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PSCommandPath" -Verb RunAs
    exit
}

$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 기존 폴더 삭제 및 새 폴더 생성
Remove-Item -Path $rawDir -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir -ItemType Directory | Out-Null
New-Item -Path $resultDir -ItemType Directory | Out-Null

# 로컬 보안 정책 내보내기
secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null

# 시스템 정보 수집
systeminfo | Out-File "$rawDir\systeminfo.txt"

# IIS 설정 파일 읽기
$applicationHostConfig = Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig | Out-File "$rawDir\iis_setting.txt"

# 임시 파일 및 폴더 삭제
Remove-Item -Path "$rawDir\*" -Force -Recurse

# 진단 결과에 따라 JSON 데이터 업데이트
if ($vulnerableUsers.Count -gt 0) {
    $json.'진단 결과' = "취약"
    $json.'현황' = $vulnerableUsers | ForEach-Object { "Everyone 그룹에 대한 전체 권한이 설정되어 있습니다: $_" }
} else {
    $json.'진단 결과' = "양호"
}

# 업데이트된 JSON 데이터 저장
$json | ConvertTo-Json | Set-Content $jsonPath

# 결과 요약
Get-Content "$resultDir\W-Window-*" | Out-File "$resultDir\security_audit_summary.txt"

# 정리 작업
Remove-Item "$rawDir\*" -Force

Write-Host "스크립트가 완료되었습니다."