# JSON 데이터 초기화
$json = @{
    분류 = "보안관리"
    코드 = "W-68"
    위험도 = "상"
    진단 항목 = "SAM 계정과 공유의 익명 열거 허용 안 함"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "익명 열거를 허용하지 않도록 시스템 정책을 설정"
}

# 관리자 권한 확인 및 요청
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"", "-Verb", "RunAs"
    exit
}

# 초기 설정 및 디렉터리 생성
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDir, $resultDir | Out-Null

# W-68 검사: 익명 열거 정책 확인
$restrictAnonymous = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\LSA").restrictanonymous
$restrictAnonymousSAM = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\LSA").RestrictAnonymousSAM

if ($restrictAnonymous -eq 1 -and $restrictAnonymousSAM -eq 1) {
    $json.현황 += "익명 SAM 계정 접근을 제한하는 설정이 적절히 구성되었습니다."
} else {
    $json.진단 결과 = "취약"
    $json.현황 += "익명 SAM 계정 접근을 제한하는 설정이 적절히 구성되지 않았습니다."
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-68.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# 결과 요약 및 출력
Get-Content -Path "$resultDir\W-68_${computerName}_diagnostic_results.json" | Out-File -FilePath "$resultDir\security_audit_summary.txt"
Write-Host "결과가 $resultDir\security_audit_summary.txt에 저장되었습니다."

# 정리 작업 및 스크립트 종료
Remove-Item "$rawDir\*" -Force
Write-Host "스크립트를 종료합니다."
