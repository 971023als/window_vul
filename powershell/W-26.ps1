$json = @{
    Classification = "계정 관리"
    Code = "W-26"
    Risk = "높음"
    Diagnosis = "비밀번호 저장을 위한 복호화 가능한 암호화 사용"
    Result = "양호"  # 기본 상태를 '양호'로 가정
    Status = @()
    Recommendation = "비밀번호 저장을 위한 복호화 가능한 암호화 사용"
}

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
