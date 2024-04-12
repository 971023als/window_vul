# JSON 데이터 초기화
$json = @{
    분류 = "보안관리"
    코드 = "W-62"
    위험도 = "상"
    진단 항목 = "백신 프로그램 설치"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "백신 프로그램 설치"
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

# ESTsoft 및 AhnLab 소프트웨어 설치 여부 확인
$softwareKeys = @("HKLM:\SOFTWARE\ESTsoft", "HKLM:\SOFTWARE\AhnLab")
$softwareInstalled = $False

foreach ($key in $softwareKeys) {
    If (Test-Path $key) {
        $softwareInstalled = $True
        $json.현황 += "$key 백신 소프트웨어가 설치되어 있습니다."
        break
    }
}

If (-not $softwareInstalled) {
    $json.현황 += "ESTsoft 또는 AhnLab 백신 소프트웨어가 설치되지 않았습니다."
    $json.진단 결과 = "취약"
}

# JSON 데이터를 파일로 저장
$jsonPath = "$resultDirectory\W-62_${computerName}_diagnostic_results.json"
$json | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath
Write-Output "진단 결과가 저장되었습니다: $jsonPath"

# 결과 요약 및 저장
Get-Content -Path "$resultDirectory\W-62_${computerName}_diagnostic_results.json" | Out-File -FilePath "$resultDirectory\security_audit_summary.txt"

Write-Output "Results have been saved to $resultDirectory\security_audit_summary.txt."

# 정리 작업
Remove-Item -Path "$rawDirectory\*" -Force

Write-Output "Script has completed."
