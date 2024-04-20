# 변수 초기화
$json = @{
  "분류": "계정 관리",
  "코드": "W-28",
  "위험도": "높음",
  "진단_항목": "비밀번호 저장에 복호화 가능한 암호화 사용하지 않기",
  "진단_결과": "양호"  // 기본 상태를 '양호'로 설정,
  "현황": [],
  "대응방안": "비밀번호 저장에 복호화 가능한 암호화 사용을 피하세요"
}


# 관리자 권한 요청
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File `"$PSCommandPath`"", "-Verb RunAs"
    exit
}

# 환경 및 디렉터리 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
$null = New-Item -Path "$rawDir\compare.txt" -ItemType File
Set-Location -Path $rawDir
[System.IO.File]::WriteAllText("$rawDir\install_path.txt", (Get-Location).Path)
systeminfo | Out-File "$rawDir\systeminfo.txt"

# IIS 설정 분석
$applicationHostConfigPath = "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
if (Test-Path $applicationHostConfigPath) {
    $applicationHostConfig = Get-Content $applicationHostConfigPath
    $applicationHostConfig | Out-File "$rawDir\iis_setting.txt"
    $applicationHostConfig | Select-String -Pattern "physicalPath|bindingInformation" | Out-File "$rawDir\iis_path1.txt"
} else {
    "$applicationHostConfigPath 경로를 찾을 수 없습니다." | Out-File "$rawDir\iis_path1.txt"
}

# IIS 중요 경로에서 단축 파일 검사
$serviceStatus = Get-Service W3SVC -ErrorAction SilentlyContinue
if ($serviceStatus.Status -eq 'Running') {
    $shortcutFound = $False
    1..5 | ForEach-Object {
        $path = Get-Content "$rawDir\path$_.txt" -ErrorAction SilentlyContinue
        if (Test-Path $path) {
            $shortcutFiles = Get-ChildItem -Path $path -Filter "*.lnk"
            if ($shortcutFiles) {
                $shortcutFound = $True
                "$path 경로에 단축 파일 (*.lnk)이 있습니다, 보안 위험이 있습니다." | Out-File "$rawDir\W-28-발견된_결과.txt" -Append
            }
        }
    }

    if ($shortcutFound) {
        $json.CurrentStatus += "IIS 중요 경로에 단축 파일이 발견되었습니다, 보안 위험이 있습니다."
        $json.DiagnosticResult = "취약"
    } else {
        $json.CurrentStatus += "IIS 중요 경로에 비인가 단축 파일이 없습니다, 보안 기준을 준수하고 있습니다."
    }
} else {
    $json.CurrentStatus += "World Wide Web Publishing Service가 실행되지 않고 있습니다, 단축 파일 검사가 필요 없습니다."
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-28.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
