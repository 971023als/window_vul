# Convert your existing hashtable to a PSCustomObject for easier manipulation
$json = [PSCustomObject]@{
    "분류" = "서비스관리"
    "코드" = "W-38"
    "위험도" = "상"
    "진단 항목" = "FTP 디렉토리 접근권한 설정"
    "진단 결과" = "양호"  # 기본 값을 "양호"로 가정
    "현황" = @()
    "대응방안" = "FTP 디렉토리 접근권한 설정"
}

# Request Administrator privileges
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "`"$PSCommandPath`"" -Verb RunAs
    Exit
}
