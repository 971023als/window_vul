$json = @{
    "분류" = "계정관리"
    "코드" = "W-12"
    "위험도" = "상"
    "진단 항목" = "패스워드최소사용기간"
    "진단 결과" = "양호"  # 기본 값을 "양호"로 가정
    "현황" = @()
    "대응방안" = "패스워드최소사용기간"
}

# 관리자 권한으로 실행되지 않았다면 관리자 권한 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "$PSCommandPath" -Verb RunAs
    Exit
}

# 콘솔 환경 설정
chcp 437 > $null
$Host.UI.RawUI.ForegroundColor = "Green"
Clear-Host

# 디렉토리 및 파일 초기화
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_$($computerName)_raw"
$resultDir = "C:\Window_$($computerName)_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory -Force | Out-Null
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
New-Item -Path "$rawDir\compare.txt" -ItemType File -Force
Get-Location | Out-File -FilePath "$rawDir\install_path.txt"
systeminfo | Out-File -FilePath "$rawDir\systeminfo.txt"

# IIS 설정 파일 복사 및 분석
Copy-Item -Path "${env:WinDir}\System32\Inetsrv\Config\applicationHost.Config" -Destination "$rawDir\iis_setting.txt"
Select-String -Path "$rawDir\iis_setting.txt" -Pattern "physicalPath|bindingInformation" | Out-File "$rawDir\iis_path1.txt"

# 최소 암호 사용 기간 분석
$localSecurityPolicy = Get-Content "$rawDir\Local_Security_Policy.txt"
$minimumPasswordAge = ($localSecurityPolicy | Where-Object { $_ -match "MinimumPasswordAge" } | ForEach-Object {
    If ($_ -match "\d+") {
        [int]$matches[0]
    }
}).FirstOrDefault()

# Update the JSON object based on the minimum password age analysis
if ($minimumPasswordAge -gt 0) {
    $json.현황 += "최소 암호 사용 기간은 설정됨: ${minimumPasswordAge}일."
} else {
    $json.진단결과 = "취약"
    $json.현황 += "최소 암호 사용 기간이 설정되지 않음."
}

# Save the JSON results to a file named "1.json"
$jsonFilePath = "$resultDir\W-12.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
