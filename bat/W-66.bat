# JSON 데이터 구조 초기화
$json = @{
    Category = "보안 관리"
    Code = "W-66"
    RiskLevel = "높음"
    DiagnosticItem = "원격 시스템 강제 종료"
    DiagnosticResult = "양호"  # 기본값으로 '양호' 가정
    Status = @()
    Mitigation = "원격 시스템 종료를 허용하거나 거부할 수 있도록 정책을 적절하게 구성"
}

# 관리자 권한 요청 및 확인
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 환경 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Windows_Security_Audit\${computerName}_raw"
$resultDir = "C:\Windows_Security_Audit\${computerName}_result"

Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDir, $resultDir -Force | Out-Null

# 원격 시스템 종료 권한 확인
try {
    $shutdownPrivilege = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "SeRemoteShutdownPrivilege"
    if ($shutdownPrivilege -match "S-1-5-32-544") {
        $json.DiagnosticResult = "취약"
        $json.Status += "원격 시스템 종료 권한이 관리자 그룹에만 할당되어 있습니다."
    } else {
        $json.Status += "원격 시스템 종료 권한이 안전하게 구성되어 있습니다."
    }
} catch {
    $json.DiagnosticResult = "오류"
    $json.Status += "원격 종료 권한 설정을 검색하는 데 실패했습니다."
}

# JSON 결과를 파일로 저장
$jsonFilePath = "$resultDir\W-66.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# 결과 요약
Write-Host "$resultDir 에 결과가 저장되었습니다."

# 정리
Remove-Item "$rawDir\*" -Force
Write-Host "스크립트가 완료되었습니다."
