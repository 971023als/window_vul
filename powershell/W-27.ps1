# 진단 결과를 위한 JSON 객체 정의
$json = @{
    Category = "계정 관리"
    Code = "W-27"
    RiskLevel = "높음"
    DiagnosticItem = "비밀번호 저장을 위한 복호화 가능한 암호화 사용"
    DiagnosticResult = "양호" # 기본 상태를 '양호'로 가정
    CurrentStatus = @()
    Recommendation = "비밀번호 저장을 위한 복호화 가능한 암호화 사용"
}

# 관리자 권한 요청
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File `"$PSCommandPath`"", "-Verb RunAs"
    exit
}

# 환경 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
$null = New-Item -Path "$rawDir\compare.txt" -ItemType File
Set-Location -Path $rawDir
(Get-Location).Path | Out-File "$rawDir\install_path.txt"
systeminfo | Out-File "$rawDir\systeminfo.txt"

# Analyze IIS configuration
Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config" | Out-File "$rawDir\iis_setting.txt"
Select-String -Path "$rawDir\iis_setting.txt" -Pattern "physicalPath|bindingInformation" | Out-File "$rawDir\iis_path1.txt"

# IISADMIN 서비스 계정 검사
$serviceStatus = Get-Service W3SVC -ErrorAction SilentlyContinue
if ($serviceStatus.Status -eq 'Running') {
    $iisAdminReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\IISADMIN" -Name "ObjectName" -ErrorAction SilentlyContinue
    if ($iisAdminReg.ObjectName -ne "LocalSystem") {
        $json.CurrentStatus += "IISADMIN 서비스가 LocalSystem 계정에서 실행되지 않고 있습니다. 특별한 조치가 필요하지 않습니다."
    } else {
        $json.CurrentStatus += "IISADMIN 서비스가 LocalSystem 계정에서 실행되고 있습니다. 권장되지 않습니다."
    }
} else {
    $json.CurrentStatus += "월드 와이드 웹 퍼블리싱 서비스가 실행되지 않고 있습니다. IIS 관련 보안 구성 검토가 필요 없습니다."
}


# Save the JSON results to a file
$jsonFilePath = "$resultDir\W-27.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
