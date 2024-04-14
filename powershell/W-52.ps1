# JSON 데이터 초기화
$json = @{
    분류 = "서비스관리"
    코드 = "W-52"
    위험도 = "상"
    진단 항목 = "불필요한 ODBC/OLE-DB 데이터 소스와 드라이브 제거"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "불필요한 ODBC/OLE-DB 데이터 소스와 드라이브 제거"
}

# 관리자 권한 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "Start-Process PowerShell -ArgumentList '-ExecutionPolicy Bypass -File `"$PSCommandPath`"' -Verb RunAs"
    exit
}

# 콘솔 환경 설정
chcp 437 > $null
$Host.UI.RawUI.BackgroundColor = "DarkGreen"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

# 기본 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_$($computerName)_raw"
$resultDir = "C:\Window_$($computerName)_result"

# 디렉터리 준비
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDir, $resultDir -Force | Out-Null

# ODBC 데이터 소스 설정 검사
Write-Host "------------------------------------------ODBC Data Sources Setting------------------------------------------"
$odbcDataSources = reg query "HKLM\SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources"
If ($odbcDataSources) {
    $json.진단 결과 = "취약"
    $json.현황 += "ODBC 데이터 소스가 구성되어 있으며, 이는 필요하지 않을 경우 취약점이 될 수 있습니다."
} Else {
    $json.현황 += "불필요한 ODBC 데이터 소스가 구성되어 있지 않으며, 시스템은 안전합니다."
}

Write-Host "------------------------------------------End of ODBC Data Sources Setting------------------------------------------"

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-52.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# 결과 요약
Get-Content "$resultDir\W-52_${computerName}_diagnostic_results.json" | Out-File "$resultDir\security_audit_summary.txt"

# 정리 작업
Remove-Item -Path $rawDir\* -Force

Write-Host "Script has completed. Results have been saved to $resultDir\security_audit_summary.txt."
