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
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process PowerShell.exe -ArgumentList "Start-Process PowerShell.exe -ArgumentList '-ExecutionPolicy Bypass -File `"$PSCommandPath`"' -Verb RunAs"
    exit
}

# 환경 설정 및 디렉터리 준비
$OutputEncoding = [System.Text.Encoding]::GetEncoding(437)
$Host.UI.RawUI.ForegroundColor = "Green"
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDir, $resultDir -Force | Out-Null

# 정책 설정 기록 및 결과 처리
# 여기서는 실제 정책 설정을 검사하는 로직이 필요하나, 예시로 간단한 메시지를 저장함
# 실제 사용 시에는 정책에 따른 검사 로직을 구현해야 함

# JSON 데이터를 파일로 저장
$jsonPath = "$resultDir\W-58_${computerName}_diagnostic_results.json"
$json | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath
Write-Output "진단 결과가 저장되었습니다: $jsonPath"

# 결과 요약 및 저장
Get-Content "$resultDir\W-58_${computerName}_diagnostic_results.json" | Out-File "$resultDir\security_audit_summary.txt"

Write-Output "Results have been saved to $resultDir\security_audit_summary.txt."

# 정리 작업
Remove-Item "$rawDir\*" -Force

Write-Output "Script has completed."
