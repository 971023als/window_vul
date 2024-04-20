$json = @{
    "분류" = "계정 관리"
    "코드" = "W-30"
    "위험도" = "tkd"
    "진단 항목" = "비밀번호 저장을 위한 복호화 가능한 암호화 사용"
    "진단 결과" = "양호"  # 기본 상태를 '양호'로 가정
    "현황" = @()
    "대응방안" = "비밀번호 저장을 위해 비복호화 가능한 암호화 사용"
}

# 관리자 권한 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "`"$PSCommandPath`"" -Verb RunAs
    exit
}

# 콘솔 설정
chcp 437 > $null
$host.UI.RawUI.BackgroundColor = "DarkGreen"
$host.UI.RawUI.ForegroundColor = "Green"
Clear-Host

# 환경 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory -Force | Out-Null

# 로컬 보안 정책 내보내기
secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null

# 설치 경로 저장
(Get-Location).Path | Out-File -FilePath "$rawDir\설치_경로.txt"

# 시스템 정보 저장
systeminfo | Out-File -FilePath "$rawDir\시스템_정보.txt"

# IIS 설정 분석
$applicationHostConfig = "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
if (Test-Path $applicationHostConfig) {
    Get-Content -Path $applicationHostConfig | Out-File -FilePath "$rawDir\iis_설정.txt"
    Select-String -Path "$rawDir\iis_설정.txt" -Pattern "physicalPath|bindingInformation" | Out-File "$rawDir\iis_경로_정보.txt"
} else {
    Write-Host "IIS 설정 파일을 찾을 수 없습니다."
}

# MetaBase.xml 복사 (해당되는 경우)
$metaBasePath = "$env:WINDIR\system32\inetsrv\MetaBase.xml"
If (Test-Path $metaBasePath) {
    Get-Content -Path $metaBasePath | Out-File -FilePath "$rawDir\iis_설정.txt" -Append
} else {
    Write-Host "MetaBase.xml 파일을 찾을 수 없습니다."
}

# W-30 진단 검사
$w3svc = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
If ($w3svc.Status -eq "Running") {
    $asaFiles = Select-String -Path "$rawDir\iis_setting.txt" -Pattern "\.asax|\.asa"
    If ($asaFiles) {
        "W-30,X,| 정책 위반: .asa 또는 .asax 파일에 대한 제한이 없습니다." | Out-File -FilePath "$resultDir\W-Window-$computerName-결과.txt" -Append
    } Else {
        "W-30,O,| 정책 준수: .asa 및 .asax 파일이 적절히 제한되어 있습니다." | Out-File -FilePath "$resultDir\W-Window-$computerName-결과.txt" -Append
    }
} Else {
    "W-30,O,| 월드 와이드 웹 퍼블리싱 서비스가 실행되지 않고 있습니다: .asa 또는 .asax 파일 검사가 필요 없습니다." | Out-File -FilePath "$resultDir\W-Window-$computerName-결과.txt" -Append
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-30.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
