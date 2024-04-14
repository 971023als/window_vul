# JSON 데이터 초기화
$json = @{
    분류 = "보안관리"
    코드 = "W-63"
    위험도 = "상"
    진단 항목 = "SAM 파일 접근 통제 설정"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "SAM 파일 접근 통제 설정"
}

# 관리자 권한으로 스크립트 실행 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 환경 설정 및 기존 정보 삭제
$computerName = $env:COMPUTERNAME
$rawDirectory = "C:\Window_${computerName}_raw"
$resultDirectory = "C:\Window_${computerName}_result"

Remove-Item -Path $rawDirectory, $resultDirectory -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDirectory, $resultDirectory -Force | Out-Null

# SAM 파일 권한 분석
$samPermissions = icacls "$env:systemroot\system32\config\SAM"
If ($samPermissions -notmatch 'Administrator|System') {
    $json.진단 결과 = "취약"
    $json.현황 += "Administrator 또는 System 그룹 외 다른 권한이 SAM 파일에 대해 발견되었습니다."
} Else {
    $json.현황 += "Administrator 및 System 그룹 권한만이 SAM 파일에 설정되어 있습니다."
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDirectory\W-63.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# 결과 요약 및 저장
Get-Content "$resultDirectory\W-63_${computerName}_diagnostic_results.json" | Out-File "$resultDirectory\security_audit_summary.txt"

Write-Host "Results have been saved to $resultDirectory\security_audit_summary.txt."

# 정리 작업
Remove-Item -Path "$rawDirectory\*" -Force

Write-Host "Script has completed."
