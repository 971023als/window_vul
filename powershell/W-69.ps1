# JSON 데이터 초기화
$json = @{
    분류 = "보안관리"
    코드 = "W-69"
    위험도 = "상"
    진단 항목 = "Autologon 기능 제어"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "Autologon 기능을 비활성화하여 보안을 강화"
}

# 관리자 권한 확인 및 요청
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process PowerShell -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $PSCommandPath -Verb RunAs
    exit
}

# 초기 설정 및 디렉터리 생성
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_$($computerName)_raw"
$resultDir = "C:\Window_$($computerName)_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
mkdir $rawDir, $resultDir | Out-Null

# W-69 검사: Autologon 설정 확인
$autoAdminLogon = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon").AutoAdminLogon

if ($autoAdminLogon -eq "1") {
    $json.진단 결과 = "취약"
    $json.현황 += "AutoAdminLogon 설정이 활성화되어 있어 보안에 취약합니다."
} else {
    $json.현황 += "AutoAdminLogon 설정이 비활성화되어 있습니다."
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-69.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# 결과 요약 및 출력
Get-Content -Path "$resultDir\W-69_${computerName}_diagnostic_results.json" | Out-File -FilePath "$resultDir\security_audit_summary.txt"
Write-Host "결과가 $resultDir\security_audit_summary.txt에 저장되었습니다."

# 정리 작업 및 스크립트 종료
Remove-Item "$rawDir\*" -Force
Write-Host "스크립트를 종료합니다."
