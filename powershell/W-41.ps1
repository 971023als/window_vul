# JSON 데이터 초기화
$json = @{
    분류 = "서비스관리"
    코드 = "W-41"
    위험도 = "상"
    진단 항목 = "DNS Zone Transfer 설정"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "DNS Zone Transfer 설정"
}

# 관리자 권한 요청
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $script = "-File `"$(Get-Location)\$($MyInvocation.MyCommand.Name)`" $args"
    Start-Process PowerShell -ArgumentList $script -Verb RunAs
    exit
}

# 콘솔 환경 설정
chcp 437 | Out-Null
$host.UI.RawUI.BackgroundColor = "DarkGreen"
$host.UI.RawUI.ForegroundColor = "Green"
Clear-Host

Write-Host "------------------------------------------설정 시작---------------------------------------"
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 이전 디렉토리 삭제 및 새 디렉토리 생성
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# DNS 보안 설정 점검 시작
Write-Host "------------------------------------------W-41 DNS 보안 설정 점검 시작------------------------------------------"
$dnsService = Get-Service "DNS" -ErrorAction SilentlyContinue
if ($dnsService.Status -eq "Running") {
    $dnsZonesRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\DNS Server\Zones"
    $secureSecondaries = Get-ItemProperty -Path $dnsZonesRegPath -Name "SecureSecondaries" -ErrorAction SilentlyContinue | Where-Object { $_.SecureSecondaries -eq 2 }

    if ($secureSecondaries) {
        $json."진단 결과" = "양호"
        $json.현황 += "DNS 전송 설정이 안전하게 구성되어 있습니다."
    } else {
        $json."진단 결과" = "취약"
        $json.현황 += "DNS 전송 설정이 취약한 구성으로 되어 있습니다. DNS 전송 설정을 보안 강화를 위해 수정해야 합니다."
    }
} else {
    $json."진단 결과" = "정보"
    $json.현황 += "DNS 서비스가 실행 중이지 않습니다."
}
Write-Host "-------------------------------------------W-41 DNS 보안 설정 점검 종료------------------------------------------"


# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-41.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath

# 정리 작업
Write-Host "정리 작업을 수행합니다..."
Remove-Item "$rawDir\*" -Force

Write-Host "스크립트를 종료합니다."

