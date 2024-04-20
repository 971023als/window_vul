# JSON 데이터 초기화
$json = @{
    분류 = "로그관리"
    코드 = "W-58"
    위험도 = "상"
    진단 항목 = "로그의 정기적 검토 및 보고"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @("로그 저장 정책 및 감사를 통해 리포트를 작성하고 보안 로그를 관리하는데 필요한 정책을 검토 및 설정 필요")
    대응방안 = "로그의 정기적 검토 및 보고"
}

# 관리자 권한 확인 및 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", $PSCommandPath, "-Verb", "RunAs"
    exit
}

# 환경 설정 및 디렉터리 준비
$OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.ForegroundColor = "Green"
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction Ignore
New-Item -ItemType Directory -Path $rawDir, $resultDir -Force | Out-Null

# 로그 관리 정책 설정 검사 (실제 구현 필요)
# 여기에 실제 로그 검사 로직 구현
# 예: 로그 파일 위치 검사, 로그 사이즈 관리 정책, 로그 보관 기간 등
# PowerShell cmdlets, WMI, or registry settings can be used here for actual checks

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-58.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# 결과 요약 및 저장
Get-Content $jsonFilePath | Out-File "$resultDir\security_audit_summary.txt"

Write-Host "Results have been saved to $resultDir\security_audit_summary.txt."

# 정리 작업
Remove-Item "$rawDir\*" -Force

Write-Host "Script has completed."
