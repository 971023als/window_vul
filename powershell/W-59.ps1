# JSON 데이터 초기화
$json = @{
    분류 = "로그관리"
    코드 = "W-59"
    위험도 = "상"
    진단 항목 = "원격으로 액세스할 수 있는 레지스트리 경로"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "원격으로 액세스할 수 있는 레지스트리 경로 차단"
}

# 관리자 권한 확인 및 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", $PSCommandPath, "-Verb", "RunAs"
    exit
}

# 환경 설정 및 디렉터리 초기화
$computerName = $env:COMPUTERNAME
$rawDirectory = "C:\Window_${computerName}_raw"
$resultDirectory = "C:\Window_${computerName}_result"

Remove-Item -Path $rawDirectory, $resultDirectory -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDirectory, $resultDirectory | Out-Null

# Remote Registry 서비스 상태 검사
$remoteRegistryStatus = Get-Service -Name "RemoteRegistry" -ErrorAction SilentlyContinue

If ($remoteRegistryStatus -and $remoteRegistryStatus.Status -eq 'Running') {
    $json.진단 결과 = "취약"
    $json.현황 += "Remote Registry Service가 활성화되어 있으며, 이는 위험합니다."
} Else {
    $json.현황 += "Remote Registry Service가 비활성화되어 있으며, 이는 안전합니다."
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDirectory\W-59.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# 결과 요약 및 저장
Get-Content -Path "$jsonFilePath" | Out-File -FilePath "$resultDirectory\security_audit_summary.txt"

Write-Host "Results have been saved to $resultDirectory\security_audit_summary.txt."

# 정리 작업
Remove-Item -Path "$rawDirectory\*" -Force

Write-Host "Script has completed."
