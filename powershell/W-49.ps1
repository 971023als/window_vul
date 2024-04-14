# JSON 데이터 초기화
$json = @{
    분류 = "서비스관리"
    코드 = "W-49"
    위험도 = "상"
    진단 항목 = "DNS 서비스 구동 점검"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "DNS 서비스 구동 점검"
}

# 관리자 권한 확인 및 요청
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process PowerShell -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", $PSCommandPath, "-Verb", "RunAs"
    exit
}

# 콘솔 환경 설정
chcp 437 | Out-Null
$host.UI.RawUI.BackgroundColor = "DarkGreen"
$host.UI.RawUI.ForegroundColor = "White"
Clear-Host

Write-Host "------------------------------------------Setting---------------------------------------"
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 이전 디렉토리 삭제 및 새 디렉토리 생성
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# DNS 서비스 동적 업데이트 설정 검사
Write-Host "------------------------------------------W-49 DNS Service Dynamic Update Check------------------------------------------"
$dnsService = Get-Service -Name "DNS" -ErrorAction SilentlyContinue
if ($dnsService.Status -eq "Running") {
    $allowUpdate = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\DNS Server\Zones" -ErrorAction SilentlyContinue).AllowUpdate
    if ($allowUpdate -eq "0") {
        $json.진단 결과 = "양호"
        $json.현황 += "DNS 서비스가 활성화되어 있으나 동적 업데이트 권한이 설정되어 있지 않은 경우, 이는 안전합니다."
    } else {
        $json.진단 결과 = "경고"
        $json.현황 += "DNS 서비스가 활성화되어 있으나 동적 업데이트 권한이 설정되어 있는 경우, 이는 위험합니다."
    }
} else {
    $json.현황 += "DNS 서비스가 비활성화되어 있으며, 이는 안전합니다."
}
Write-Host "-------------------------------------------End------------------------------------------"

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-49.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# 결과 요약
Write-Host "Results have been saved to: C:\Window_$computerName\_result\security_audit_summary.txt"
Get-Content "$resultDir\W-49_${computerName}_diagnostic_results.json" | Out-File "$resultDir\security_audit_summary.txt"

# 정리 작업
Write-Host "Cleaning up..."
Remove-Item "$rawDir\*" -Force

Write-Host "Script has ended."
