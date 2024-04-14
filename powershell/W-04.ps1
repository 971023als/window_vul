# JSON 객체 초기화
$json = @{
    분류 = "계정관리"
    코드 = "W-04"
    위험도 = "상"
    진단항목 = "계정 잠금 임계값 설정"
    진단결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "계정 잠금 임계값 설정"
}

# 관리자 권한 확인 및 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "관리자 권한이 필요합니다..."
    Start-Process PowerShell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# 초기 환경 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# 보안 정책, 시스템 정보 등 수집
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
$securityConfig = "$rawDir\Local_Security_Policy.txt"
$securityPolicy = secedit /export /areas SECURITYPOLICY /cfg "$securityConfig"

# 시스템 정보 수집
systeminfo | Out-File -FilePath "$rawDir\systeminfo.txt"

# IIS 설정 수집
$applicationHostConfig = Get-Content -Path "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig | Out-File -FilePath "$rawDir\iis_setting.txt"

# 계정 잠금 임계값 검사
If (Test-Path $securityConfig) {
    $lockoutThreshold = (Get-Content $securityConfig | Select-String "LockoutBadCount").ToString().Split('=')[1].Trim()

    # 계정 잠금 임계값 검사 후 JSON 객체 업데이트
    If ($lockoutThreshold -gt 5) {
        $json.진단결과 = "취약"
        $json.현황 += "계정 잠금 임계값이 5회 시도보다 많게 설정되어 있습니다."
    } ElseIf ($lockoutThreshold -eq 0) {
        $json.진단결과 = "취약"
        $json.현황 += "계정 잠금 임계값이 설정되지 않았습니다(없음)."
    } Else {
        $json.현황 += "계정 잠금 임계값이 준수 범위 내에 설정되었습니다."
    }
}

# JSON 결과를 파일로 저장
$jsonFilePath = "$resultDir\W-04.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
