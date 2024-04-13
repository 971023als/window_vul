# Define the initial JSON structure
$json = @{
        "분류": "보안관리",
        "코드": "W-76",
        "위험도": "상",
        "진단 항목": "사용자별 홈 디렉터리 권한 설정",
        "진단 결과": "양호",  # 기본 값을 "양호"로 가정
        "현황": [],
        "대응방안": "사용자별 홈 디렉터리 권한 설정"
    }
# 관리자 권한 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process PowerShell -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# JSON 데이터 로드
$jsonPath = "path_to_your_json_file.json"
$json = Get-Content $jsonPath | ConvertFrom-Json

# 설정 및 초기화
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDir, $resultDir | Out-Null

# 로컬 보안 정책 내보내기
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"

# 시스템 정보 수집
systeminfo | Out-File "$rawDir\systeminfo.txt"

# IIS 설정 분석
$applicationHostConfigPath = "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig = Get-Content $applicationHostConfigPath
$applicationHostConfig | Out-File "$rawDir\iis_setting.txt"

# 사용자 홈 디렉토리 권한 검사 및 결과 기록
$users = Get-ChildItem C:\Users -Directory | Where-Object { $_.Name -notmatch '^(All|Default|Public|.*\.)$' }
$vulnerableUsers = @()
foreach ($user in $users) {
    $acl = Get-Acl "C:\Users\$($user.Name)"
    $resultPath = "$resultDir\W-Window-$computerName-result.txt"
    If ($acl.Access | Where-Object { $_.FileSystemRights -eq "FullControl" -and $_.IdentityReference -eq "Everyone" }) {
        "W-76,O,| 취약: Everyone 그룹에 대한 전체 권한이 설정되어 있습니다. | 사용자: $($user.Name)" | Out-File $resultPath -Append
        $vulnerableUsers += $user.Name
    } Else {
        "W-76,X,| 안전: Everyone 그룹에 대한 전체 권한이 설정되지 않았습니다. | 사용자: $($user.Name)" | Out-File $resultPath -Append
    }
}

# 진단 결과에 따라 JSON 데이터 업데이트
if ($vulnerableUsers.Count -gt 0) {
    $json.'진단 결과' = "취약"
    $json.'현황' = $vulnerableUsers | ForEach-Object { "Everyone 그룹에 대한 전체 권한이 설정되어 있습니다: $_" }
} else {
    $json.'진단 결과' = "양호"
}

# 업데이트된 JSON 데이터 저장
$json | ConvertTo-Json | Set-Content $jsonPath

# 결과 요약
Get-Content "$resultDir\W-Window-*" | Out-File "$resultDir\security_audit_summary.txt"

# 정리 작업
Remove-Item "$rawDir\*" -Force

Write-Host "스크립트가 완료되었습니다."
