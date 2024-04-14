# JSON 데이터 초기화
$json = @{
    분류 = "로그관리"
    코드 = "W-60"
    위험도 = "상"
    진단 항목 = "이벤트 로그 관리 설정"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "이벤트 로그 관리 설정 조정"
}

# 관리자 권한 확인 및 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"' -Verb RunAs" -Wait
    exit
}

# 환경 설정 및 디렉터리 초기화
$computerName = $env:COMPUTERNAME
$rawDirectory = "C:\Window_${computerName}_raw"
$resultDirectory = "C:\Window_${computerName}_result"

Remove-Item -Path $rawDirectory, $resultDirectory -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDirectory, $resultDirectory | Out-Null

# 이벤트 로그 설정 검사
$eventLogKeys = @("Application", "Security", "System")
$inadequateSettings = $False

foreach ($key in $eventLogKeys) {
    $path = "HKLM:\SYSTEM\CurrentControlSet\Services\Eventlog\$key"
    $maxSize = (Get-ItemProperty -Path $path -Name "MaxSize").MaxSize
    $retention = (Get-ItemProperty -Path $path -Name "Retention").Retention
    If ($maxSize -lt 10485760 -or $retention -eq 0) {
        $inadequateSettings = $True
        $json.현황 += "MaxSize for $key: $maxSize, Retention for $key: $retention"
    }
}

If ($inadequateSettings) {
    $json.진단 결과 = "취약"
} else {
    $json.현황 += "All event logs are adequately configured."
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-60.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# 결과 요약 및 저장
Get-Content -Path "$resultDirectory\W-60_${computerName}_diagnostic_results.json" | Out-File -FilePath "$resultDirectory\security_audit_summary.txt"

Write-Host "Results have been saved to $resultDirectory\security_audit_summary.txt."

# 정리 작업
Remove-Item -Path "$rawDirectory\*" -Force

Write-Host "Script has completed."
