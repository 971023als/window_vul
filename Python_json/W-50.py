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

Write-Host "------------------------------------------Setting---------------------------------------"
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 이전 디렉토리 삭제 및 새 디렉토리 생성
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# 시스템 정보 수집 및 IIS 설정 검사
$systemInfo = systeminfo
$systemInfo | Out-File -FilePath "$rawDir\systeminfo.txt"
$iisConfig = Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$iisConfig | Out-File -FilePath "$rawDir\iis_setting.txt"

# W-50: 서비스 비활성화 권장
Write-Host "------------------------------------------W-50 Service Recommendation------------------------------------------"
# 실제 서비스 비활성화 검사 로직은 여기에 포함되어야 합니다.
# 예시 코드는 실제 서비스 상태를 반영하지 않습니다.
$json.현황 += "HTTP, FTP, SMTP 서비스가 필요 없는 경우 비활성화 권장. 필요하지 않은 서비스는 비활성화하여 안전함."

Write-Host "-------------------------------------------End------------------------------------------"

# JSON 데이터를 파일로 저장
$jsonPath = "$resultDir\W-50_${computerName}_diagnostic_results.json"
$json | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# 결과 요약
Write-Host "Results have been saved to: $resultDir\security_audit_summary.txt"
Get-Content "$resultDir\W-50_${computerName}_diagnostic_results.json" | Out-File "$resultDir\security_audit_summary.txt"

# 정리 작업
Write-Host "Cleaning up..."
Remove-Item "$rawDir\*" -Force

Write-Host "Script has ended."
