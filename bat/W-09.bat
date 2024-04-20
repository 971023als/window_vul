$json = @{
    분류 = "계정관리"
    코드 = "W-09"
    위험도 = "상"
    진단항목 = "패스워드 복잡성 설정"
    진단결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "패스워드 복잡성 설정"
}

# 관리자 권한 확인
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "관리자 권한이 필요합니다..."
    Start-Process PowerShell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# 콘솔 환경 설정
[Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding(437)
$host.UI.RawUI.BackgroundColor = "DarkGreen"
$host.UI.RawUI.ForegroundColor = "Green"
Clear-Host

# 초기 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# 보안 정책 파일 생성 및 시스템 정보 수집
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
systeminfo | Out-File "$rawDir\systeminfo.txt"

# 패스워드 복잡성 설정 검사
$securityPolicy = Get-Content "$rawDir\Local_Security_Policy.txt"
$passwordComplexity = $securityPolicy | Where-Object { $_ -match "PasswordComplexity" }

# 패스워드 복잡성 정책 검사 후 JSON 객체 업데이트
if ($passwordComplexity -match "1") {
    $json.현황 += "패스워드 복잡성 정책이 적절히 설정되어 있습니다."
} else {
    $json.진단결과 = "취약"
    $json.현황 += "패스워드 복잡성 정책이 적절히 설정되지 않았습니다."
}

# JSON 결과를 파일로 저장
$jsonFilePath = "$resultDir\W-09.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
