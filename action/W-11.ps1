# JSON 객체 초기화
$json = @{
    분류 = "계정관리"
    코드 = "W-11"
    위험도 = "상"
    진단 항목 = "패스워드 최대 사용 기간"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "패스워드 최대 사용 기간"
}

# 관리자 권한으로 실행 중인지 확인
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-File", "`"$PSCommandPath`"", "-NoProfile", "-ExecutionPolicy Bypass" -Verb RunAs
    Exit
}

# 콘솔 환경 설정
chcp 437 | Out-Null
$host.UI.RawUI.BackgroundColor = "DarkGreen"
Clear-Host

# 변수 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 디렉터리 초기화
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory -Force | Out-Null

# 기본 정보 수집
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
New-Item -Path "$rawDir\compare.txt" -ItemType File -Force | Out-Null
(Get-Location).Path > "$rawDir\install_path.txt"
systeminfo > "$rawDir\systeminfo.txt"

# IIS 설정 파일 읽기
$applicationHostConfig = Get-Content -Path "${env:WinDir}\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig | Out-File -FilePath "$rawDir\iis_setting.txt"

# 최대암호사용기간 분석
$localSecurityPolicy = Get-Content "$rawDir\Local_Security_Policy.txt"
$maximumPasswordAge = ($localSecurityPolicy | Where-Object { $_ -match "MaximumPasswordAge\s*=\s*(\d+)" }).Matches.Groups[1].Value

# 보안 정책 분석 후 JSON 객체 업데이트
if ($maximumPasswordAge) {
    if ([int]$maximumPasswordAge -le 90) {
        $json.현황 += "최대 암호 사용 기간 정책이 준수됩니다. ${maximumPasswordAge}일로 설정됨."
    } else {
        $json.진단결과 = "취약"
        $json.현황 += "최대 암호 사용 기간 정책이 준수되지 않습니다. ${maximumPasswordAge}일로 설정됨."
    }
} else {
    $json.현황 += "최대암호사용기간 정책 정보를 찾을 수 없습니다."
}

# JSON 결과를 파일로 저장
$jsonFilePath = "$resultDir\W-11.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
