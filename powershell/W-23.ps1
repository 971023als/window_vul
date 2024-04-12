$json = @{
        "분류": "계정관리",
        "코드": "W-23",
        "위험도": "상",
        "진단 항목": "해독 가능한 암호화를 사용하여 암호 저장",
        "진단 결과": "양호",  # 기본 값을 "양호"로 가정
        "현황": [],
        "대응방안": "해독 가능한 암호화를 사용하여 암호 저장"
    }

# 관리자 권한 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "$PSCommandPath", "-Verb", "RunAs"
    Exit
}

# 콘솔 환경 설정 및 초기 설정
chcp 437 | Out-Null
$host.UI.RawUI.ForegroundColor = "Green"

$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -Force
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
$null = New-Item -Path "$rawDir\compare.txt" -ItemType File
(Get-Location).Path | Out-File "$rawDir\install_path.txt"
systeminfo | Out-File "$rawDir\systeminfo.txt"

# IIS 설정 분석
$applicationHostConfigPath = "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig = Get-Content $applicationHostConfigPath
$applicationHostConfig | Out-File "$rawDir\iis_setting.txt"
Select-String -Path "$rawDir\iis_setting.txt" -Pattern "physicalPath|bindingInformation" | ForEach-Object {
    $_.Matches.Value >> "$rawDir\iis_path1.txt"
}

# Assuming $iisPaths is correctly populated earlier in the script, as the provided snippet doesn't show its initialization

# Update the JSON object based on the directory browsing check
If ($serviceStatus.Status -eq "Running") {
    Foreach ($path in $iisPaths) {
        If (Test-Path $path\web.config) {
            $webConfig = Get-Content "$path\web.config"
            If ($webConfig -match "<directoryBrowse .*enabled=`"true`"") {
                $json.현황 += "불안전한 상태: 디렉토리 브라우징이 활성화되어 있습니다."
                $json.진단결과 = "취약"
                Break
            }
        }
    }
    If (!$?) {
        $json.현황 += "안전한 상태: 디렉토리 브라우징이 비활성화되어 있습니다."
        $json.진단결과 = "양호"
    }
} Else {
    $json.현황 += "안전한 상태: World Wide Web Publishing Service가 실행되지 않고 있습니다."
    $json.진단결과 = "양호"
}

# Save the JSON results to a file
$jsonFilePath = "$resultDir\W-Window-${computerName}-diagnostic_result.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
