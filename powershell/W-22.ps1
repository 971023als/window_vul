$json = @{
        "분류": "계정관리",
        "코드": "W-22",
        "위험도": "상",
        "진단 항목": "해독 가능한 암호화를 사용하여 암호 저장",
        "진단 결과": "양호",  # 기본 값을 "양호"로 가정
        "현황": [],
        "대응방안": "해독 가능한 암호화를 사용하여 암호 저장"
    }

# 관리자 권한 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $script = "-File `"" + $MyInvocation.MyCommand.Definition + "`""
    Start-Process PowerShell.exe -ArgumentList $script -Verb RunAs
    Exit
}

# 콘솔 환경 설정 및 초기 설정
chcp 437 | Out-Null
$host.UI.RawUI.ForegroundColor = "Green"

$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -Force
mkdir $rawDir, $resultDir
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
New-Item -Path "$rawDir\compare.txt" -ItemType File -Value $null
Set-Location -Path $rawDir
(Get-Location).Path | Out-File "$rawDir\install_path.txt"
systeminfo | Out-File "$rawDir\systeminfo.txt"

# IIS 설정 분석
$applicationHostConfig = Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig | Out-File "$rawDir\iis_setting.txt"
Select-String -Path "$rawDir\iis_setting.txt" -Pattern "physicalPath|bindingInformation" | ForEach-Object {
    $_.Matches.Value >> "$rawDir\iis_path1.txt"
}

# Update the JSON object based on the "World Wide Web Publishing Service" status analysis
if ($serviceStatus.Status -eq "Running") {
    $json.현황 += "위험 상태: 'World Wide Web Publishing Service'가 활성화되어 있습니다."
    $json.진단결과 = "취약"
} else {
    $json.현황 += "정상 상태: 'World Wide Web Publishing Service'가 비활성화되어 있습니다."
    $json.진단결과 = "양호"
}

# Optionally, append HTTP paths information to the JSON object if the service is running
if ($httpPaths) {
    $json.현황 += "활성화된 HTTP 경로: $($httpPaths.Count)"
    $json.HTTP경로 = $httpPaths -join "; "
}

# Save the JSON results to a file
$jsonFilePath = "$resultDir\W-Window-${computerName}-diagnostic_result.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath

