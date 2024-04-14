$json = @{
    "분류" = "보안관리"
    "코드" = "W-79"
    "위험도" = "상"
    "진단 항목" = "파일 및 디렉토리 보호"
    "진단 결과" = "양호" # 기본 값을 "양호"로 가정
    "현황" = @()
    "대응방안" = "파일 및 디렉토리 보호"
}

# 관리자 권한 확인 및 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "$PSCommandPath", "-Verb", "RunAs"
    exit
}

$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 디렉터리 생성 및 초기화
$dirs = @($rawDir, $resultDir)
foreach ($dir in $dirs) {
    if (Test-Path $dir) {
        Remove-Item $dir -Recurse -Force
    }
    New-Item -Path $dir -ItemType Directory -ErrorAction Continue | Out-Null
}

# 로컬 보안 정책 내보내기 및 시스템 정보 수집
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
systeminfo | Out-File "$rawDir\systeminfo.txt"

# IIS 설정 분석
$iisConfigPath = "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
if (Test-Path $iisConfigPath) {
    Get-Content $iisConfigPath | Select-String "physicalPath|bindingInformation" | Out-File "$rawDir\iis_setting.txt"
}

# NTFS 파일 시스템 검사
if (Test-Path "C:\") {
    $ntfsCheck = (Get-Acl "C:\").AccessToString -match "NT AUTHORITY"
    If ($ntfsCheck) {
        "W-79,O,|" | Out-File "$resultDir\W-Window-$computerName-result.txt" -Append
    } Else {
        "W-79,X,|" | Out-File "$resultDir\W-Window-$computerName-result.txt" -Append
    }
}

# 결과 요약 및 저장
Get-Content "$resultDir\W-Window-*" | Out-File "$resultDir\security_audit_summary.txt"

# 정리 작업
Remove-Item "$rawDir\*" -Force
