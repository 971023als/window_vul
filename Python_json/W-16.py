$json = @{
        "분류": "계정관리",
        "코드": "W-16",
        "위험도": "상",
        "진단 항목": "최근 암호 기억",
        "진단 결과": "양호",  # 기본 값을 "양호"로 가정
        "현황": [],
        "대응방안": "최근 암호 기억"
    }

# 관리자 권한 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $script = "-File `"" + $MyInvocation.MyCommand.Definition + "`""
    Start-Process PowerShell.exe -ArgumentList $script -Verb RunAs
    Exit
}

# 콘솔 환경 설정
chcp 437 | Out-Null
$host.UI.RawUI.BackgroundColor = "DarkGreen"

# 초기 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
fsutil file createnew "$rawDir\compare.txt" 0 | Out-Null
(Get-Location).Path | Out-File "$rawDir\install_path.txt"
systeminfo | Out-File "$rawDir\systeminfo.txt"

# IIS 설정 분석
$applicationHostConfig = Get-Content -Path "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig | Out-File -FilePath "$rawDir\iis_setting.txt"
Select-String -Path "$rawDir\iis_setting.txt" -Pattern "physicalPath|bindingInformation" | ForEach-Object {
    $_.Line >> "$rawDir\iis_path1.txt"
}

# 비밀번호 정책 분석
$localSecurityPolicy = Get-Content "$rawDir\Local_Security_Policy.txt"
$passwordHistorySize = ($localSecurityPolicy | Where-Object { $_ -match "PasswordHistorySize" }).Split("=")[1].Trim()

# Update the JSON object based on the "PasswordHistorySize" policy analysis
if ($passwordHistorySize -gt 11) {
    $json.현황 += "준수 확인됨: 비밀번호 이력 크기가 11개 이전 비밀번호를 초과하도록 설정됨."
    $json.진단결과 = "양호"
} else {
    $json.진단결과 = "취약"
    $json.현황 += "준수하지 않음 감지됨: 비밀번호 이력 크기가 11개 이전 비밀번호를 초과하지 않음."
}

# Save the JSON results to a file
$jsonFilePath = "$resultDir\W-16.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
