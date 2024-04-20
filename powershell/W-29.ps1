# 변수 초기화
$분류 = "계정 관리"
$코드 = "W-29"
$위험도 = "높음"
$진단_항목 = "비밀번호 저장을 위한 복호화 가능한 암호화 사용"
$진단_결과 = "양호"  # 기본 상태를 '양호'로 가정, 진단 후 상태 업데이트 예정
$현황 = @()
$대응방안 = "비밀번호 저장을 위한 복호화 가능한 암호화 사용을 피하세요"

$json = @{
    분류 = $분류
    코드 = $코드
    위험도 = $위험도
    진단_항목 = $진단_항목
    진단_결과 = $진단_결과
    현황 = $현황
    대응방안 = $대응방안
}

# 관리자 권한 요청
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 환경 설정 및 디렉터리 구성
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory

# 로컬 보안 정책 내보내기
secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null
New-Item -Path "$rawDir\compare.txt" -ItemType File

# 시스템 정보 저장
systeminfo | Out-File "$rawDir\systeminfo.txt"

# IIS 설정 분석
$applicationHostConfig = Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig | Out-File "$rawDir\iis_setting.txt"
$applicationHostConfig | Select-String -Pattern "physicalPath|bindingInformation" | Out-File "$rawDir\iis_path1.txt"
(Get-Content "$rawDir\iis_path1.txt" -Raw) | Out-File "$rawDir\line.txt"

# 분석을 위한 경로 추출
1..5 | ForEach-Object {
    $pathNumber = $_
    (Get-Content "$rawDir\line.txt" -Raw) -split '\*' | Select-Object -Index ($pathNumber - 1) | Out-File "$rawDir\path$pathNumber.txt"
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-29.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
