# Initialize diagnostics JSON object
$json = @{
    분류 = "계정관리"
    코드 = "W-25"
    위험도 = "상"
    진단 항목 = "Use of decryptable encryption to store passwords"
    진단 결과 = "양호" # Assuming 'Good' as the default
    현황 = @()
    대응방안 = "Use decryptable encryption to store passwords"
}

# 관리자 권한 확인 및 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "`"$PSCommandPath`"", "-Verb", "RunAs"
    "관리자 권한이 필요합니다. 스크립트를 다시 시작합니다."
    Exit
}

# 환경 및 초기 설정
chcp 437 | Out-Null
$host.UI.RawUI.ForegroundColor = "Green"
$computerName = $env:COMPUTERNAME
$directories = @("C:\Window_$($computerName)_raw", "C:\Window_$($computerName)_result")

# 디렉터리 설정
foreach ($dir in $directories) {
    If (Test-Path $dir) { Remove-Item -Path $dir -Recurse -Force }
    New-Item -Path $dir -ItemType Directory | Out-Null
    "$dir 디렉터리를 생성하였습니다."
}

# 시스템 정보 및 보안 정책 내보내기
secedit /export /cfg "$($directories[0])\Local_Security_Policy.txt"
(Get-Location).Path | Out-File "$($directories[0])\install_path.txt"
systeminfo | Out-File "$($directories[0])\systeminfo.txt"
"IIS 설정을 분석하고 있습니다."

# IIS 구성 분석
$applicationHostConfigPath = "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig = Get-Content $applicationHostConfigPath
$applicationHostConfig | Out-File "$($directories[0])\iis_setting.txt"
$enableParentPaths = $applicationHostConfig | Select-String -Pattern "asp enableParentPaths"

# 진단 결과 분석
If (Get-Service W3SVC -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' } -and $enableParentPaths) {
    $json.진단 결과 = "취약"
    $json.현황 += "부모 경로 사용 설정이 활성화되어 있어 보안 위반."
} Else {
    $json.진단 결과 = "양호"
    $json.현황 += If ($enableParentPaths) { "부모 경로 사용 설정이 활성화되어 있으나, IIS 서비스 비활성화 상태." } Else { "부모 경로 사용 설정이 비활성화되어 있어 보안 준수." }
}

# 결과 파일 저장
$jsonFilePath = "$resultDir\W-25.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
"진단 결과가 저장되었습니다: $jsonFilePath"

# 스크립트 종료 메시지
"스크립트 실행 완료"
