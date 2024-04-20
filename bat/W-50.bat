# JSON 데이터 초기화
$json = @{
    분류 = "서비스관리"
    코드 = "W-50"
    위험도 = "상"
    진단 항목 = "HTTP/FTP/SMTP 배너 차단"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "HTTP/FTP/SMTP 배너 차단"
}

# 관리자 권한 확인 및 요청
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process PowerShell -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", $PSCommandPath, "-Verb", "RunAs"
    exit
}

# 콘솔 환경 설정
chcp 437 | Out-Null
$host.UI.RawUI.BackgroundColor = "DarkGreen"
$host.UI.RawUI.ForegroundColor = "White"
Clear-Host

Write-Host "------------------------------------------설정 시작---------------------------------------"
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 이전 디렉토리 삭제 및 새 디렉토리 생성
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# 서비스 구성 검사
Write-Host "------------------------------------------W-50 Service Configuration Check------------------------------------------"
$iisConfig = Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$ftpSites = $iisConfig | Select-String -Pattern "ftpServer"
$smtpConfig = Get-WmiObject -Query "SELECT * FROM SmtpService" -Namespace "root\MicrosoftIISv2"

if (!$ftpSites -and !$smtpConfig) {
    $json.진단 결과 = "양호"
    $json.현황 += "HTTP, FTP, SMTP 서비스는 현재 비활성화되어 있거나 배너가 적절하게 숨겨져 있습니다."
} else {
    $json.진단 결과 = "경고"
    $json.현황 += "하나 이상의 서비스가 배너 정보를 외부에 노출하고 있을 수 있습니다. 적절한 설정 변경이 필요합니다."
}
Write-Host "-------------------------------------------검사 종료------------------------------------------"

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-50.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# 결과 요약
Write-Host "Results have been saved to: $resultDir\security_audit_summary.txt"
Get-Content "$resultDir\W-50_${computerName}_diagnostic_results.json" | Out-File "$resultDir\security_audit_summary.txt"

# 정리 작업
Write-Host "Cleaning up..."
Remove-Item "$rawDir\*" -Force

Write-Host "Script has ended."
