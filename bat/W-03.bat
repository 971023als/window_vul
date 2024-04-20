# JSON 객체 초기화
$json = @{
    분류 = "계정관리"
    코드 = "W-03"
    위험도 = "상"
    진단항목 = "불필요한 계정 제거"
    진단결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "불필요한 계정 제거"
}

# 관리자 권한 확인 및 요청
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 콘솔 환경 설정
[Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding(437)
Write-Host "------------------------------------------설정---------------------------------------"

$computerName = $env:COMPUTERNAME
$rawPath = "C:\Window_${computerName}_raw"
$resultPath = "C:\Window_${computerName}_result"

# 기존 폴더 및 파일 제거 및 새 폴더 생성
Remove-Item -Path $rawPath, $resultPath -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawPath, $resultPath -ItemType Directory | Out-Null

# 보안 정책, 시스템 정보 등 수집
secedit /export /cfg "$rawPath\Local_Security_Policy.txt"
New-Item -Path "$rawPath\compare.txt" -ItemType File -Force
Get-Location > "$rawPath\install_path.txt"
systeminfo > "$rawPath\systeminfo.txt"

# IIS 설정 정보 수집
$applicationHostConfig = Get-Content "$env:WINDIR\System32\inetsrv\config\applicationHost.Config"
$applicationHostConfig > "$rawPath\iis_setting.txt"

# 사용자 계정 정보 수집 및 분석
$users = (net user | Select-String -Pattern "\w+" -AllMatches).Matches.Value
foreach ($user in $users) {
    $userInfo = net user $user
    $isActive = $userInfo -match "계정 활성 상태\s+.*Yes"
    if ($isActive) {
        $json.진단결과 = "취약"
        $json.현황 += "활성화된 계정: $user"
        "$userInfo" | Out-File -FilePath "$rawPath\user_$user.txt"
    }
}

# JSON 결과를 파일로 저장
$jsonFilePath = "$resultPath\W-03.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath

Write-Host "스크립트 실행 완료"
