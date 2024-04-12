$json = @{
        "분류": "계정관리",
        "코드": "W-13",
        "위험도": "상",
        "진단 항목": "해독 가능한 암호화를 사용하여 암호 저장",
        "진단 결과": "양호",  # 기본 값을 "양호"로 가정
        "현황": [],
        "대응방안": "해독 가능한 암호화를 사용하여 암호 저장"
    }

# 관리자 권한 확인 및 요청
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "$PSCommandPath", "-Verb", "RunAs"
    exit
}

# 콘솔 환경 설정
chcp 437 | Out-Null
$Host.UI.RawUI.ForegroundColor = "Green"

# 초기 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_$computerName`_raw"
$resultDir = "C:\Window_$computerName`_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
New-Item -Path "$rawDir\compare.txt" -ItemType File | Out-Null
$installPath = (Get-Location).Path
$installPath | Out-File -FilePath "$rawDir\install_path.txt"
systeminfo | Out-File -FilePath "$rawDir\systeminfo.txt"

# IIS 설정 분석
$applicationHostConfig = Get-Content -Path "${env:WinDir}\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig | Out-File -FilePath "$rawDir\iis_setting.txt"
$bindingInfo = Select-String -Path "$rawDir\iis_setting.txt" -Pattern "physicalPath|bindingInformation"
$bindingInfo | Out-File -FilePath "$rawDir\iis_path1.txt"

# 보안 정책 분석 - DontDisplayLastUserName
$securityPolicy = Get-Content -Path "$rawDir\Local_Security_Policy.txt"
$policyAnalysis = $securityPolicy | Where-Object { $_ -match "DontDisplayLastUserName" -and $_ -match ",1" }

# Update the JSON object based on the "DontDisplayLastUserName" policy analysis
if ($policyAnalysis) {
    $json.진단결과 = "양호"
    $json.현황 += "준수: 마지막으로 로그온한 사용자 이름을 표시하지 않는 정책이 활성화되어 있습니다."
} else {
    $json.진단결과 = "취약"
    $json.현황 += "미준수: 마지막으로 로그온한 사용자 이름을 표시하지 않는 정책이 비활성화되어 있습니다."
}

# Save the JSON results to a file
$jsonFilePath = "$resultDir\W-Window-$computerName-diagnostic_result.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
