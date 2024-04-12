$json = @{
    분류 = "보안관리"
    코드 = "W-74"
    위험도 = "상"
    진단 항목 = "세션 연결을 중단하기 전에 필요한 유휴시간"
    진단 결과 = "양호"  # Assume the default value is "Good"
    현황 = @()
    대응방안 = "세션 연결을 중단하기 전에 필요한 유휴시간 설정 조정"
}

# Request administrator privileges
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -Verb RunAs -ArgumentList "-File `"$PSCommandPath`"", "-ExecutionPolicy Bypass"
    Exit
}

# Environment setup
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# Delete existing data and create directories
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# Export local security policy
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"

# Verify LanManServer parameter settings
$enableForcedLogOff = (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanManServer\Parameters").EnableForcedLogOff
$autoDisconnect = (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanManServer\Parameters").AutoDisconnect

if ($enableForcedLogOff -eq 1 -and $autoDisconnect -eq 15) {
    $json.현황 += "서버에서 강제 로그오프 및 자동 연결 끊김이 적절하게 설정되었습니다."
} else {
    $json.진단 결과 = "취약"
    $json.현황 += "서버에서 강제 로그오프 및 자동 연결 끊김 설정이 적절하지 않습니다."
}

# Convert the JSON object to a JSON string and save to a file
$jsonPath = "$resultDir\W-74_${computerName}_diagnostic_results.json"
$json | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# Cleanup
Remove-Item "$rawDir\*" -Force

Write-Host "스크립트가 완료되었습니다."
