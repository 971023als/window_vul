# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Service_Banner_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-33"
$riskLevel = "하"
$diagnosisItem = "HTTP/FTP/SMTP 배너 차단"
$remedialAction = "IIS URL 재작성을 통한 Server 헤더 제거, FTP/SMTP 사용자 지정 배너 설정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 서비스 배너 차단 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    $vulnerabilities = @()
    $iisInstalled = Get-Module -ListAvailable WebAdministration

    # 3-1. HTTP (IIS) 배너 점검
    $w3svc = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
    if ($w3svc -and $w3svc.Status -eq "Running") {
        # URL Rewrite 모듈 설치 여부 확인 (가이드라인 권장 방식)
        $urlRewritePath = "$env:SystemRoot\System32\inetsrv\rewrite.dll"
        if (-not (Test-Path $urlRewritePath)) {
            $vulnerabilities += "HTTP: URL 재작성(URL Rewrite) 모듈이 설치되어 있지 않아 Server 헤더 노출 위험이 있습니다."
        }
    }

    # 3-2. FTP 배너 점검
    $ftpsvc = Get-Service -Name "FTPSVC" -ErrorAction SilentlyContinue
    if ($ftpsvc -and $ftpsvc.Status -eq "Running" -and $iisInstalled) {
        Import-Module WebAdministration
        # FTP 메시지 설정의 bannerMessage가 비어있거나 기본값인지 확인
        $ftpMsg = Get-WebConfigurationProperty -Filter "/system.ftpServer/messages" -Name "bannerMessage" -PSPath "IIS:\"
        if ([string]::IsNullOrWhiteSpace($ftpMsg.Value)) {
            $vulnerabilities += "FTP: 사용자 지정 배너 메시지가 설정되어 있지 않습니다."
        }
    }

    # 3-3. SMTP 배너 점검
    $smtpsvc = Get-Service -Name "SMTPSVC" -ErrorAction SilentlyContinue
    if ($smtpsvc -and $smtpsvc.Status -eq "Running") {
        # SMTP 배너는 메타베이스 또는 레지스트리에서 확인 (버전별 상이)
        # 여기서는 서비스 구동 시 주의 대상으로 분류
        $vulnerabilities += "SMTP: 서비스가 구동 중입니다. 접속 배너(ConnectResponse) 설정 확인이 필요합니다."
    }

    # 4. 최종 판정 로직
    if ($vulnerabilities.Count -gt 0) {
        $result = "취약"
        $statusMsg = $vulnerabilities -join " / "
        $color = "Red"
    } else {
        $result = "양호"
        $statusMsg = "주요 서비스(HTTP, FTP, SMTP)가 구동되지 않거나 배너 관리 정책이 적용된 것으로 보입니다."
        $color = "Green"
    }

} catch {
    $result = "오류"
    $statusMsg = "점검 중 에러 발생: $($_.Exception.Message)"
    $color = "Yellow"
}

# 5. 결과 객체 생성
$report = [PSCustomObject]@{
    "Category"       = $category
    "Code"           = $code
    "Risk Level"     = $riskLevel
    "Diagnosis Item" = $diagnosisItem
    "Result"         = $result
    "Current Status" = $statusMsg
    "Remedial Action"= $remedialAction
}

# 6. 콘솔 출력 및 CSV 저장
Write-Host "[결과] : $result" -ForegroundColor $color
Write-Host "[현황] : $statusMsg"
Write-Host "------------------------------------------------"

$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray