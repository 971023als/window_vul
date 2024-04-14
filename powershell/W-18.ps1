$json = @{
        "분류": "계정관리",
        "코드": "W-18",
        "위험도": "상",
        "진단 항목": "원격터미널 접속 가능한 사용자 그룹 제한",
        "진단 결과": "양호",  # 기본 값을 "양호"로 가정
        "현황": [],
        "대응방안": "원격터미널 접속 가능한 사용자 그룹 제한"
    }

# 관리자 권한 요청
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    $script = "-File `"" + $MyInvocation.MyCommand.Definition + "`""
    Start-Process PowerShell.exe -ArgumentList $script -Verb RunAs
    exit
}

# 콘솔 환경 설정 및 초기 설정
chcp 437 | Out-Null
$host.UI.RawUI.ForegroundColor = "Green"

$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
New-Item -Path "$rawDir\compare.txt" -ItemType File -Value $null
Set-Location -Path $rawDir
(Get-Location).Path | Out-File -FilePath "install_path.txt"
systeminfo | Out-File -FilePath "systeminfo.txt"

# IIS 설정 분석
$applicationHostConfig = Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig | Out-File -FilePath "$rawDir\iis_setting.txt"
Select-String -Path "$rawDir\iis_setting.txt" -Pattern "physicalPath|bindingInformation" | Out-File -FilePath "$rawDir\iis_path1.txt"

# 사용자 그룹 분석
$userList = Get-Content "$rawDir\user.txt"
$userRemoteDetails = @()

foreach ($user in $userList) {
    $userInfo = net user $user
    if ($userInfo -like "*Remote Desktop Users*") {
        $userRemoteDetails += "----------------------------------------------------"
        $userRemoteDetails += ($userInfo | Select-String "User name")
        $userRemoteDetails += ($userInfo | Select-String "Remote Desktop Users")
        $userRemoteDetails += "----------------------------------------------------"
    }
}

$userRemoteDetails | Out-File "$rawDir\user_Remote.txt"

# Update the JSON object based on the unauthorized users check
if ($unauthorizedUsers) {
    $json.현황 += "무단 사용자가 'Remote Desktop Users' 그룹에 발견되었습니다."
    $json.진단결과 = "취약"
} else {
    $json.현황 += "'Remote Desktop Users' 그룹에 무단 사용자가 없습니다. 준수 상태가 확인되었습니다."
    $json.진단결과 = "양호"
}

# Save the JSON results to a file
$jsonFilePath = "$resultDir\W-18.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
