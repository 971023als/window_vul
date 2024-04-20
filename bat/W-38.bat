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

Write-Host "------------------------------------------W-38 점검 시작------------------------------------------"

$isSecure = $true # 기본적으로 보안이 유지되고 있다고 가정하고, 그렇지 않은 경우 업데이트합니다.

# "Everyone"에 "FullControl"이 있는지 점검합니다.
If (Test-Path "$rawDir\FTP_PATH.txt") {
    Get-Content "$rawDir\FTP_PATH.txt" | ForEach-Object {
        $filePath = $_
        $acl = Get-Acl $filePath
        $hasFullControl = $acl.Access | Where-Object {
            $_.FileSystemRights -match "FullControl" -and $_.IdentityReference -eq "Everyone"
        }

        # 진단 결과에 따라 $isSecure 업데이트
        if ($hasFullControl) {
            $isSecure = $false
        }
    }
}

# 진단 결과에 따라 JSON 객체 업데이트
if ($isSecure) {
    $json."진단 결과" = "양호"
    $json.현황 += "FTP 디렉토리 접근권한이 적절히 설정됨."
} else {
    $json."진단 결과" = "위험"
    $json.현황 += "EVERYONE 그룹에 대한 FullControl 접근 권한이 발견되어 취약합니다."
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-38.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
