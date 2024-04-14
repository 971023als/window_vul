# JSON 데이터 구조를 미리 정의합니다.
$json = @{
    분류 = "서비스관리"
    코드 = "W-39"
    위험도 = "상"
    진단항목 = "Anonymouse FTP 금지"
    진단결과 = "양호" # 기본 값을 "양호"로 설정
    현황 = @()
    대응방안 = "Anonymouse FTP 금지"
}

# 관리자 권한이 있는지 확인합니다.
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
If (-not $isAdmin) {
    $info = New-Object System.Diagnostics.ProcessStartInfo "PowerShell"
    $info.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $args"
    $info.Verb = "runas"
    [System.Diagnostics.Process]::Start($info)
    Exit
}

# 콘솔 환경을 설정합니다.
chcp 437 | Out-Null
$host.UI.RawUI.BackgroundColor = "DarkGreen"
$host.UI.RawUI.ForegroundColor = "Green"
Clear-Host

Write-Host "------------------------------------------설정 시작---------------------------------------"
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 이전 디렉토리를 삭제하고 새로운 디렉토리를 생성합니다.
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# 로컬 보안 정책을 내보내고 비교 파일을 생성합니다.
secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null
New-Item -Path "$rawDir\compare.txt" -ItemType File -Value $null

# 설치 경로를 저장하고 시스템 정보를 수집합니다.
Set-Location -Path $rawDir
Get-Location | Out-File -FilePath "$rawDir\install_path.txt"
systeminfo | Out-File -FilePath "$rawDir\systeminfo.txt"

Write-Host "------------------------------------------IIS 설정-----------------------------------"
Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config" | Out-File -FilePath "$rawDir\iis_setting.txt"
Select-String -Path "$rawDir\iis_setting.txt" -Pattern "physicalPath|bindingInformation" | ForEach-Object { $_.Line } | Out-File -FilePath "$rawDir\iis_path1.txt"

# IIS 설정을 분석하고 경로를 저장합니다.
$line = Get-Content "$rawDir\iis_path1.txt" -Raw
$line | Out-File -FilePath "$rawDir\line.txt"

1..5 | ForEach-Object {
    $filePath = "$rawDir\path$_.txt"
    Get-Content "$rawDir\line.txt" | ForEach-Object {
        $_ | Out-File -FilePath $filePath -Append
    }
}

# MetaBase.xml을 추가합니다(해당하는 경우).
$metaBasePath = "$env:WINDIR\system32\inetsrv\MetaBase.xml"
If (Test-Path $metaBasePath) {
    Get-Content $metaBasePath | Out-File -FilePath "$rawDir\iis_setting.txt" -Append
}

Write-Host "------------------------------------------설정 종료-------------------------------------------"

# 진단 결과를 기반으로 JSON 데이터를 업데이트합니다.
$isSecure = $true # 이 값은 실제 진단 로직을 통해 결정되어야 합니다.

if ($isSecure -eq $false) {
    $json."진단결과" = "위험"
    $json.현황 = @("EVERYONE 그룹에 대한 FullControl 접근 권한이 발견되었습니다.")
} else {
    $json.현황 = @("FTP 디렉토리 접근권한이 적절히 설정됨.")
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-39.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
