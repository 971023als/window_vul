# JSON 데이터 초기화
$json = @{
    분류 = "패치관리"
    코드 = "W-55"
    위험도 = "상"
    진단 항목 = "최신 HOT FIX 적용"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "최신 HOT FIX 적용"
}

# 관리자 권한 요청
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "$PSCommandPath", "-Verb", "RunAs"
    exit
}

# 환경 설정
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.BackgroundColor = "DarkGreen"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

# 변수 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 디렉터리 생성 및 초기화
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction Ignore
New-Item -Path $rawDir, $resultDir -ItemType Directory -Force | Out-Null

# 핫픽스 검사
$hotfixId = "KB3214628"
$hotfixCheck = Get-HotFix -Id $hotfixId -ErrorAction SilentlyContinue
if ($hotfixCheck) {
    $json.진단 결과 = "양호"
    $json.현황 += "핫픽스 $hotfixId이 설치되어 있습니다. 이는 보안 상태가 양호함을 나타냅니다."
} else {
    $json.진단 결과 = "취약"
    $json.현황 += "핫픽스 $hotfixId이 설치되어 있지 않습니다. 최신 핫픽스를 적용하는 것이 권장됩니다."
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-55.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# 결과 요약 및 저장
Get-Content $jsonFilePath | Out-File "$resultDir\security_audit_summary.txt"

# 정리 작업
Remove-Item "$rawDir\*" -Force

Write-Host "Script has completed. Results have been saved to $resultDir\security_audit_summary.txt."
