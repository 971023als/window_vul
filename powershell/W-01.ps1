# 진단 결과 JSON 객체
$json = @{
    분류 = "계정관리"
    코드 = "W-01"
    위험도 = "상"
    진단항목 = "Administrator 계정 이름 바꾸기"
    진단결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "Administrator 계정 이름 변경"
}

# 관리자 권한 확인
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "관리자 권한이 필요합니다..."
    Start-Process PowerShell -ArgumentList "Start-Process PowerShell -ArgumentList '-ExecutionPolicy Bypass -File `"$PSCommandPath`"' -Verb RunAs" -Verb RunAs
    Exit
}

# 기본 설정
$computerName = $env:COMPUTERNAME
$rawPath = "C:\Window_${computerName}_raw"
$resultPath = "C:\Window_${computerName}_result"

Remove-Item -Path $rawPath -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $resultPath -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawPath -ItemType Directory -Force
New-Item -Path $resultPath -ItemType Directory -Force

# 로컬 보안 정책 내보내기
secedit /EXPORT /CFG "$rawPath\Local_Security_Policy.txt"

# 시스템 정보 수집
systeminfo | Out-File -FilePath "$rawPath\systeminfo.txt"

# IIS 설정 수집
$applicationHostConfig = Get-Content -Path $env:WinDir\System32\Inetsrv\Config\applicationHost.Config
$applicationHostConfig | Out-File -FilePath "$rawPath\iis_setting.txt"

# 추가적인 처리와 검사 로직은 여기에 구현합니다...

# 관리자 계정 이름 변경 여부 확인
$adminNameChange = Select-String -Path "$rawPath\Local_Security_Policy.txt" -Pattern "NewAdministratorName"
if ($adminNameChange -ne $null) {
    $json.진단결과 = "취약"
    $json.현황 += "관리자 계정의 기본 이름이 변경되지 않았습니다."
} else {
    $json.현황 += "관리자 계정의 기본 이름이 변경되었습니다."
}

# 진단 결과 JSON 파일로 저장
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath "$resultPath\diagnostic_result.json"

# 이후에는 결과 보고서를 생성하는 코드를 추가할 수 있습니다.