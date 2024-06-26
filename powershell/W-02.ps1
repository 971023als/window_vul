# 게스트 계정 상태 확인 후 JSON 객체 업데이트
$json = @{
    분류 = "계정관리"
    코드 = "W-02"
    위험도 = "상"
    진단항목 = "Guest 계정 상태"
    진단결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "Guest 계정 상태 변경"
}

# 관리자 권한 확인 및 요청
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 콘솔 환경 설정
$OutputEncoding = [System.Text.Encoding]::GetEncoding(437)
$host.UI.RawUI.BackgroundColor = 'DarkBlue'
$host.UI.RawUI.ForegroundColor = 'White'
Clear-Host

# 기본 디렉터리 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory -Force | Out-Null

# 로컬 보안 정책 내보내기 및 기본 파일 생성
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
New-Item -Path "$rawDir\compare.txt" -ItemType File

# 시스템 정보 수집
systeminfo | Out-File -FilePath "$rawDir\systeminfo.txt"

# IIS 설정 수집
$applicationHostConfig = Get-Content -Path $env:WinDir\System32\Inetsrv\Config\applicationHost.Config
$applicationHostConfig | Out-File -FilePath "$rawDir\iis_setting.txt"

# 게스트 계정 정보 수집 및 분석
$guestAccountInfo = net user guest
$isActive = $guestAccountInfo -match "Account active\s+Yes"

if ($isActive) {
    $json.진단결과 = "취약"
    $json.현황 += "게스트 계정이 활성화 되어 있는 위험 상태로, 조치가 필요합니다."
} else {
    $json.현황 += "게스트 계정이 비활성화 상태로 유지되고 있으므로 안전합니다."
}

# JSON 객체를 JSON 파일로 저장
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath "$resultDir\W-02.json"

Write-Host "스크립트 실행 완료"
