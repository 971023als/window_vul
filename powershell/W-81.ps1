$json = @{
    "분류" = "보안관리"
    "코드" = "W-81"
    "위험도" = "상"
    "진단 항목" = "시작프로그램 목록 분석"
    "진단 결과" = "양호"  # 기본 값을 "양호"로 가정
    "현황" = @()
    "대응방안" = "시작프로그램 목록 분석"
}

# 관리자 권한 확인 및 스크립트 초기 설정
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "$PSCommandPath", "-Verb", "RunAs"
    exit
}

$computerName = $env:COMPUTERNAME
$resultDir = "C:\Window_${computerName}_result"

# 결과 디렉터리 생성
if (-not (Test-Path $resultDir)) {
    New-Item -Path $resultDir -ItemType Directory -Force | Out-Null
}

# 로컬 보안 정책 내보내기
$securityPolicy = secedit /export /cfg "$env:TEMP\secpol.cfg" 2>$null
$secpolContent = Get-Content "$env:TEMP\secpol.cfg"
$maximumPasswordAge = $secpolContent | Where-Object { $_ -match "MaximumPasswordAge\s*=\s*(\d+)" }

if ($matches[1]) {
    if ($matches[1] -lt 90) {
        $message = "W-81: 암호 최대 사용 기간이 90일 미만으로 설정됨. 설정값: $($matches[1])"
    } else {
        $message = "W-81: 암호 최대 사용 기간이 90일 이상으로 설정되어 있음. 설정값: $($matches[1])"
    }
    "$message" | Out-File "$resultDir\W-81-${computerName}-result.txt"
} else {
    "W-81: 암호 최대 사용 기간 데이터를 찾을 수 없음." | Out-File "$resultDir\W-81-${computerName}-result.txt"
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-81.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath

# 스크립트 종료 전 임시 파일 삭제
Remove-Item "$env:TEMP\secpol.cfg" -Force

Write-Host "스크립트 실행 완료"
