$json = @{
        "분류": "계정관리",
        "코드": "W-11",
        "위험도": "상",
        "진단 항목": "해독 가능한 암호화를 사용하여 암호 저장",
        "진단 결과": "양호",  # 기본 값을 "양호"로 가정
        "현황": [],
        "대응방안": "해독 가능한 암호화를 사용하여 암호 저장"
    }

# 관리자 권한이 없으면 관리자 권한으로 스크립트 재실행
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Start-Process PowerShell.exe -ArgumentList "-File", "`"$PSCommandPath`"", "-NoProfile", "-ExecutionPolicy Bypass" -Verb RunAs
    Exit
}

# 콘솔 환경 설정
chcp 437
$host.UI.RawUI.BackgroundColor = "DarkGreen"
Clear-Host

# 변수 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 디렉토리 초기화
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory -Force | Out-Null
Remove-Item -Path "${resultDir}\W-Window-*.txt" -ErrorAction SilentlyContinue

# 기본 정보 수집
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
New-Item -Path "$rawDir\compare.txt" -ItemType File -Force | Out-Null
(Get-Location).Path > "$rawDir\install_path.txt"
systeminfo > "$rawDir\systeminfo.txt"

# IIS 설정 파일 내용 복사
$applicationHostConfig = Get-Content -Path "${env:WinDir}\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig | Out-File -FilePath "$rawDir\iis_setting.txt"

# physicalPath 및 bindingInformation 검색 및 파일 생성
Select-String -Path "$rawDir\iis_setting.txt" -Pattern "physicalPath|bindingInformation" | ForEach-Object {
    $_.Line | Out-File -FilePath "$rawDir\iis_path1.txt" -Append
}

Set-Location -Path $rawDir
Get-Content "user.txt" | ForEach-Object {
    $user = $_
    $userInfo = net user $user
    If ($userInfo -match "계정 활성.*예") {
        "----------------------------------------------------" | Out-File "user_pw.txt" -Append
        (net user $user | Select-String "사용자 이름|암호 마지막 설정") | Out-File "user_pw.txt" -Append
        "----------------------------------------------------" | Out-File "user_pw.txt" -Append
    }
    Else {
        Write-Output "비활성 계정은 건너뜁니다."
    }
}

# Update the JSON object based on the policy analysis
if ($policyInfo -match "\d+") {
    $maximumPasswordAge = $Matches[0]
    if ($maximumPasswordAge -lt 91) {
        $json.진단결과 = "양호"
        $json.현황 += "최대 암호 사용 기간 정책이 준수됩니다. 90일 미만으로 설정됨."
    } else {
        $json.진단결과 = "취약"
        $json.현황 += "최대 암호 사용 기간 정책이 준수되지 않습니다. 90일 이상으로 설정됨."
    }
} else {
    $json.현황 += "최대암호사용기간 정책 정보를 찾을 수 없습니다."
}

# Save the JSON results to a file
$jsonFilePath = "$resultDir\W-Window-${computerName}-diagnostic_result.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath

# Ensure to close the statement properly
