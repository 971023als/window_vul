$json = @{
        "분류": "계정관리",
        "코드": "W-17",
        "위험도": "상",
        "진단 항목": "콘솔 로그온 시 로컬 계정에서 빈 암호 사용 제한",
        "진단 결과": "양호",  # 기본 값을 "양호"로 가정
        "현황": [],
        "대응방안": "콘솔 로그온 시 로컬 계정에서 빈 암호 사용 제한"
    }

# 관리자 권한 요청
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $script = $MyInvocation.MyCommand.Definition
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", $script -Verb RunAs
    exit
}

# 콘솔 환경 설정
chcp 437 | Out-Null
$host.UI.RawUI.ForegroundColor = "Green"

# 초기 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
mkdir $rawDir, $resultDir | Out-Null
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
fsutil file createnew "$rawDir\compare.txt" 0 | Out-Null
(Get-Location).Path | Out-File "$rawDir\install_path.txt"
systeminfo | Out-File "$rawDir\systeminfo.txt"

# IIS 설정 분석
$applicationHostConfig = Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig | Out-File "$rawDir\iis_setting.txt"
Select-String -Path "$rawDir\iis_setting.txt" -Pattern "physicalPath|bindingInformation" | Out-File "$rawDir\iis_path1.txt"

# "LimitBlankPasswordUse" 보안 정책 감사
$localSecurityPolicy = Get-Content "$rawDir\Local_Security_Policy.txt"
$limitBlankPasswordUsePolicy = $localSecurityPolicy | Where-Object { $_ -match "LimitBlankPasswordUse" }

# Update the JSON object based on the "LimitBlankPasswordUse" policy analysis
if ($limitBlankPasswordUsePolicy -match "1") {
    $json.현황 += "준수 확인됨: 'LimitBlankPasswordUse' 정책이 올바르게 적용됨."
    $json.진단결과 = "양호"
} else {
    $json.진단결과 = "취약"
    $json.현황 += "준수하지 않음 감지됨: 'LimitBlankPasswordUse' 정책이 올바르게 적용되지 않음."
}

# Save the JSON results to a file
$jsonFilePath = "$resultDir\W-Window-${computerName}-diagnostic_result.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
