# JSON 객체 초기화
$json = @{
    분류 = "계정관리"
    코드 = "W-10"
    위험도 = "상"
    진단항목 = "패스워드 최소 암호 길이"
    진단결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "패스워드 최소 암호 길이"
}

# 관리자 권한으로 실행 중인지 확인
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # 현재 스크립트를 관리자 권한으로 재실행
    Start-Process PowerShell -ArgumentList "-File `"$PSCommandPath`"", "-NoProfile", "-ExecutionPolicy Bypass" -Verb RunAs
    Exit
}

# 콘솔 창 설정
chcp 437
$host.UI.RawUI.BackgroundColor = "DarkGreen"
Clear-Host

# 필요한 디렉토리 삭제 및 생성
$computerName = $env:COMPUTERNAME
$baseDir = "C:\Window_${computerName}"
$rawDir = "${baseDir}_raw"
$resultDir = "${baseDir}_result"

Remove-Item -Path "${rawDir}", "${resultDir}" -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path "${rawDir}", "${resultDir}" -ItemType Directory -Force | Out-Null

# 초기 파일 생성 및 시스템 정보 수집
secedit /export /cfg "${rawDir}\Local_Security_Policy.txt"
fsutil file createnew "${rawDir}\compare.txt" 0
Get-Location > "${rawDir}\install_path.txt"
systeminfo > "${rawDir}\systeminfo.txt"

# IIS 설정 파일 읽기
$iisConfig = Get-Content -Path "${env:WinDir}\System32\Inetsrv\Config\applicationHost.Config"
$iisConfig > "${rawDir}\iis_setting.txt"

# "user.txt" 파일 생성 후 읽어오기
Set-Content -Path "${rawDir}\user.txt" -Value "User1", "User2"

cd "${rawDir}"

# "user.txt" 파일에서 사용자 정보 읽어오기
Get-Content "user.txt" | ForEach-Object {
    $user = $_.Trim()
    $userInfo = net user $user
    if ($userInfo -match "계정 활성 상태\s*:\s*예") {
        "----------------------------------------------------" >> "user_pw.txt"
        net user $user | Select-String "사용자 이름|마지막으로 암호 설정됨" >> "user_pw.txt"
        "----------------------------------------------------" >> "user_pw.txt"
    }
}

# 로컬 보안 정책 정보 읽어오기
$policyInfo = Get-Content "${rawDir}\Local_Security_Policy.txt"

# 최대암호사용기간 분석 후 JSON 객체 업데이트
if ($policyInfo -match "최대암호사용기간\s*:\s*(\d+)") {
    $maxAge = [int]$Matches[1]
    if ($maxAge -lt 91) {
        $json.진단결과 = "양호"
        $json.현황 += "최대암호사용기간이 91일 미만으로 설정되어 정책을 준수합니다."
    } else {
        $json.진단결과 = "취약"
        $json.현황 += "최대암호사용기간이 91일 이상으로 설정되어 정책을 준수하지 않습니다."
    }
} else {
    $json.현황 += "최대암호사용기간 정책 정보를 찾을 수 없습니다."
}

# JSON 결과를 파일로 저장
$jsonFilePath = "${resultDir}\W-10.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
