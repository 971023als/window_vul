# JSON 데이터 초기화
$json = @{
    분류 = "패치관리"
    코드 = "W-56"
    위험도 = "상"
    진단 항목 = "백신 프로그램 업데이트"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "백신 프로그램 업데이트"
}

# 관리자 권한 확인 및 요청
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "`"$PSCommandPath`"", "-Verb", "RunAs"
    exit
}

# 환경 설정
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.ForegroundColor = "Green"

# 변수 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 디렉터리 준비
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction Ignore
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# 보안 소프트웨어 설치 여부 확인
$antivirusSoftware = Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntivirusProduct -ErrorAction SilentlyContinue

# 결과 기록
if ($antivirusSoftware) {
    $json.진단 결과 = "양호"
    $json.현황 += "보안 프로그램이 설치되어 있으며 활성화되어 있습니다."
} else {
    $json.진단 결과 = "취약"
    $json.현황 += "보안 프로그램이 설치되어 있지 않거나 활성화되어 있지 않습니다."
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-56.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# 결과 요약 및 저장
Get-Content $jsonFilePath | Out-File "$resultDir\security_audit_summary.txt"

Write-Host "Results have been saved to $resultDir\security_audit_summary.txt."

# 정리 작업
Remove-Item -Path "$rawDir\*" -Force

Write-Host "Script has completed."
