$json = @{
    "분류" = "계정관리"
    "코드" = "W-31"
    "위험도" = "상"
    "진단 항목" = "해독 가능한 암호화를 사용하여 암호 저장"
    "진단 결과" = "양호"  # 기본 값을 "양호"로 가정
    "현황" = @()
    "대응방안" = "해독 가능한 암호화를 사용하여 암호 저장"
}

# 관리자 권한 확인 및 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "`"$PSCommandPath`"" -Verb RunAs
    exit
}

# 콘솔 설정
chcp 437 > $null
$host.UI.RawUI.BackgroundColor = "DarkGreen"
$host.UI.RawUI.ForegroundColor = "Green"
Clear-Host

$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 이전 디렉토리 삭제 및 새 디렉토리 생성
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory -Force | Out-Null

# 로컬 보안 정책 내보내기 및 기타 초기 설정
secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null
New-Item -Path "$rawDir\compare.txt" -ItemType File -Force | Out-Null
(Get-Location).Path | Out-File -FilePath "$rawDir\install_path.txt"
systeminfo | Out-File -FilePath "$rawDir\systeminfo.txt"

# IIS 설정 복사
$applicationHostConfig = "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
Get-Content -Path $applicationHostConfig | Out-File -FilePath "$rawDir\iis_setting.txt"
Select-String -Path "$rawDir\iis_setting.txt" -Pattern "physicalPath|bindingInformation" | Out-File "$rawDir\iis_path1.txt"

# MetaBase.xml 복사 (해당하는 경우)
$metaBasePath = "$env:WINDIR\system32\inetsrv\MetaBase.xml"
If (Test-Path $metaBasePath) {
    Get-Content -Path $metaBasePath | Out-File -FilePath "$rawDir\iis_setting.txt" -Append
}

# W-31 분석 로직을 여기에 추가합니다. 예를 들면:
# "W-31에 대한 특정 분석이나 검사를 수행하는 코드"

Write-Output "------------------------------------------W-31------------------------------------------"
# W-31 결과 출력. 예를 들어:
If ($true) { # 조건에 따라 변경하세요.
    "W-31,O,| 정책 준수: 설명에 맞게 적절한 설정이 구성되어 있습니다." | Out-File "$resultDir\W-Window-$computerName-result.txt" -Append
} Else {
    "W-31,X,| 정책 위반: 설명에 맞지 않게 설정이 구성되어 있습니다." | Out-File "$resultDir\W-Window-$computerName-result.txt" -Append
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-31.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
