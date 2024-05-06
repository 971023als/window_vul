# 진단 JSON 객체 초기화
$json = @{
    분류 = "계정 관리"
    코드 = "W-26"
    위험도 = "높음"
    진단항목 = "비밀번호 저장을 위한 복호화 가능한 암호화 사용"
    진단결과 = "양호"  # 기본 상태를 '양호'로 가정
    현황 = @()
    대응방안 = "비밀번호 저장을 위한 복호화 불가능한 암호화 사용"
}

# 이 JSON 구조는 계정 관리 카테고리의 보안 진단을 위해 사용됩니다.
# '진단항목'은 비밀번호를 저장할 때 복호화 가능한 암호화 방법을 사용하는지를 평가합니다.
# '대응방안'은 보다 안전한 비밀번호 저장 방법을 제안하며, 비밀번호를 저장할 때 복호화 불가능한 암호화를 사용할 것을 권장합니다.


# 관리자 권한 요청
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File `"$PSCommandPath`"", "-Verb RunAs"
    exit
}

# 환경 설정
$computerName = $env:COMPUTERNAME
$directories = @("C:\Window_${computerName}_raw", "C:\Window_${computerName}_result")

foreach ($dir in $directories) {
    Remove-Item -Path $dir -Recurse -ErrorAction SilentlyContinue
    New-Item -Path $dir -ItemType Directory | Out-Null
}

# 보안 정책 내보내기 및 시스템 정보 수집
secedit /export /cfg "$($directories[0])\Local_Security_Policy.txt"
Get-Location | Out-File "$($directories[0])\install_path.txt"
systeminfo | Out-File "$($directories[0])\systeminfo.txt"


# IIS 설정 분석
$applicationHostConfigPath = "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
Get-Content $applicationHostConfigPath | Out-File "$($directories[0])\iis_setting.txt"
Select-String -Path "$($directories[0])\iis_setting.txt" -Pattern "physicalPath|bindingInformation" | Out-File "$($directories[0])\iis_path1.txt"
# 취약한 디렉토리 검사
$serviceRunning = Get-Service W3SVC -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' }
$vulnerableDirs = @(
    "c:\program files\common files\system\msadc\sample",
    "c:\winnt\help\iishelp",
    "c:\inetpub\iissamples",
    "${env:SystemRoot}\System32\Inetsrv\IISADMPWD"
)
$vulnerableFound = $vulnerableDirs | Where-Object { Test-Path $_ }

if ($serviceRunning -and $vulnerableFound) {
    $json.Result = "취약"
    $json.Status += "정책 위반 감지: 취약한 디렉토리가 발견되었습니다."
} else {
    $json.Result = "안전"
    $json.Status += "규정 준수: 취약한 디렉토리가 발견되지 않았거나 IIS 서비스가 실행되지 않고 있습니다."
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-26.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
