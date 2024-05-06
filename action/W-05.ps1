# JSON 객체 초기화
$json = @{
    분류 = "계정관리"
    코드 = "W-05"
    위험도 = "상"
    진단항목 = "해독 가능한 암호화를 사용하여 암호 저장"
    진단결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "해독 가능한 암호화를 사용하여 암호 저장 방지"
}

# 관리자 권한 확인 및 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "관리자 권한이 필요합니다..."
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process PowerShell.exe -ArgumentList $arguments -Verb RunAs
    Exit
}

# 초기 환경 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory -Force | Out-Null

# 보안 정책 수집
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"

# 시스템 정보 수집
systeminfo | Out-File -FilePath "$rawDir\systeminfo.txt"

# IIS 구성 수집
$applicationHostConfig = Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig | Out-File -FilePath "$rawDir\iis_setting.txt"
$metabaseConfig = Get-Content "$env:WinDir\System32\inetsrv\MetaBase.xml"
$metabaseConfig | Out-File -FilePath "$rawDir\iis_setting.txt" -Append

# 가역 암호화 정책 검사
$securityPolicyFile = "$rawDir\Local_Security_Policy.txt"
if (Test-Path $securityPolicyFile) {
    $localSecurityPolicy = Get-Content $securityPolicyFile
    $clearTextPasswordSetting = $localSecurityPolicy | Where-Object { $_ -match "ClearTextPassword" }

    If ($clearTextPasswordSetting -match "0") {
        $json.현황 += "가역 암호화를 사용하여 비밀번호 저장 정책이 '사용 안 함'으로 설정되어 있습니다."
    } Else {
        $json.진단결과 = "취약"
        $json.현황 += "가역 암호화를 사용하여 비밀번호 저장 정책이 적절히 구성되지 않았습니다."
    }
}

# JSON 결과를 파일로 저장
$jsonFilePath = "$resultDir\W-05.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
