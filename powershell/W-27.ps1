# 진단 결과를 위한 JSON 객체 정의
$json = @{
    분류 = "계정 관리"
    코드 = "W-27"
    위험도 = "높음"
    진단항목 = "비밀번호 저장을 위한 복호화 가능한 암호화 사용"
    진단결과 = "양호"  # 기본 상태를 '양호'로 가정
    현황 = @()
    대응방안 = "비밀번호 저장을 위한 복호화 불가능한 암호화 사용"
}

# 이 JSON 구조는 계정 관리에 대한 보안 진단을 목적으로 합니다.
# '진단항목'은 비밀번호 저장 시 복호화 가능한 암호화를 사용하는 문제를 평가합니다.
# '대응방안'은 비밀번호를 보다 안전하게 저장하기 위해 복호화 불가능한 암호화 기술을 사용할 것을 권장합니다.


# 관리자 권한 요청
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File `"$PSCommandPath`"", "-Verb RunAs"
    exit
}

# 환경 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue -Force
New-Item -Path $rawDir, $resultDir -ItemType Directory -Force | Out-Null
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
$null = New-Item -Path "$rawDir\compare.txt" -ItemType File
Set-Location -Path $rawDir
[System.IO.File]::WriteAllText("$rawDir\install_path.txt", (Get-Location).Path)
systeminfo | Out-File "$rawDir\systeminfo.txt"

# IIS 설정 분석
$applicationHostConfigPath = "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
if (Test-Path $applicationHostConfigPath) {
    Get-Content $applicationHostConfigPath | Out-File "$rawDir\iis_setting.txt"
    Select-String -Path "$rawDir\iis_setting.txt" -Pattern "physicalPath|bindingInformation" | Out-File "$rawDir\iis_path1.txt"
} else {
    Write-Output "IIS configuration file not found."
}

# IISADMIN 서비스 계정 검사
$serviceStatus = Get-Service W3SVC -ErrorAction SilentlyContinue
if ($serviceStatus.Status -eq 'Running') {
    $iisAdminReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\IISADMIN" -Name "ObjectName" -ErrorAction SilentlyContinue
    if ($iisAdminReg -and $iisAdminReg.ObjectName -ne "LocalSystem") {
        $json.CurrentStatus += "IISADMIN 서비스가 LocalSystem 계정에서 실행되지 않고 있습니다. 특별한 조치가 필요하지 않습니다."
    } elseif ($iisAdminReg) {
        $json.CurrentStatus += "IISADMIN 서비스가 LocalSystem 계정에서 실행되고 있습니다. 권장되지 않습니다."
    }
} else {
    $json.CurrentStatus += "월드 와이드 웹 퍼블리싱 서비스가 실행되지 않고 있습니다. IIS 관련 보안 구성 검토가 필요 없습니다."
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-27.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
