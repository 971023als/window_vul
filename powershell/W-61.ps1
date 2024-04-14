# JSON 데이터 초기화
$json = @{
    분류 = "로그관리"
    코드 = "W-61"
    위험도 = "상"
    진단 항목 = "원격에서 이벤트 로그 파일 접근 차단"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "원격에서 이벤트 로그 파일 접근 차단"
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

# 디렉토리 권한 검사
$directories = @("$env:systemroot\system32\logfiles", "$env:systemroot\system32\config")
$vulnerabilityFound = $False

foreach ($dir in $directories) {
    $acl = Get-Acl $dir
    foreach ($ace in $acl.Access) {
        If ($ace.IdentityReference -eq "Everyone") {
            $vulnerabilityFound = $True
            $json.현황 += "취약: Everyone 그룹 권한이 발견되었습니다. - $dir"
            break
        }
    }
}

If (-not $vulnerabilityFound) {
    $json.현황 += "안전: Everyone 그룹 권한이 발견되지 않았습니다."
} else {
    $json.진단 결과 = "취약"
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-61.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# 결과 요약 및 저장
Get-Content -Path "$resultDirectory\W-61_${computerName}_diagnostic_results.json" | Out-File -FilePath "$resultDirectory\security_audit_summary.txt"

Write-Host "Results have been saved to $resultDirectory\security_audit_summary.txt."

# 정리 작업
Remove-Item -Path "$rawDirectory\*" -Force

Write-Host "Script has completed."
