# JSON 데이터 초기화
$json = @{
    Category = "보안 관리"
    Code = "W-68"
    RiskLevel = "높음"
    DiagnosticItem = "SAM 계정 및 공유의 익명 열거 허용 안 함"
    DiagnosticResult = "양호"  # 기본값으로 '양호' 가정
    Status = @()
    Countermeasure = "시스템 정책을 구성하여 익명 열거를 허용하지 않도록 설정"
}

# 관리자 권한 확인 및 요청
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 환경 및 디렉토리 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Windows_Security_Audit\${computerName}_raw"
$resultDir = "C:\Windows_Security_Audit\${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDir, $resultDir -Force | Out-Null

# 익명 열거 제한 확인
try {
    $restrictAnonymous = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\LSA" -Name "restrictanonymous"
    $restrictAnonymousSAM = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\LSA" -Name "RestrictAnonymousSAM"

    if ($restrictAnonymous -eq 1 -and $restrictAnonymousSAM -eq 1) {
        $json.Status += "시스템이 SAM 계정 및 공유의 익명 열거를 제한하는 데 적절하게 구성되었습니다."
    } else {
        $json.DiagnosticResult = "취약"
        $json.Status += "시스템이 SAM 계정 및 공유의 익명 열거를 제한하는 데 적절하게 구성되지 않았습니다."
    }
} catch {
    $json.DiagnosticResult = "오류"
    $json.Status += "익명 열거 정책 설정을 검색하는 데 실패했습니다."
}

# JSON 결과를 파일로 저장
$jsonFilePath = "$resultDir\W-68.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# 정리 및 스크립트 완료
Remove-Item "$rawDir\*" -Force
Write-Host "스크립트가 완료되었습니다. 결과가 $resultDir 에 저장되었습니다."
