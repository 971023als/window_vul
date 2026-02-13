# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "DNS_Zone_Transfer_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-25"
$riskLevel = "상"
$diagnosisItem = "DNS Zone Transfer 설정"
$remedialAction = "DNS 영역 전송을 '허용 안 함'으로 설정하거나, 승인된 특정 서버(IP)로만 제한"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] DNS Zone Transfer 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # DNS 서비스 존재 및 상태 확인
    $dnsService = Get-Service -Name "DNS" -ErrorAction SilentlyContinue
    
    if ($null -eq $dnsService -or $dnsService.Status -ne "Running") {
        $result = "양호"
        $status = "DNS 서비스가 설치되어 있지 않거나 중지 상태입니다."
        $color = "Green"
    } else {
        # DNS 서버 모듈 필요 (DNS 서버 역할이 설치된 경우 기본 제공)
        if (!(Get-Command Get-DnsServerZone -ErrorAction SilentlyContinue)) {
            $result = "오류"
            $status = "DNS 관리 도구가 설치되어 있지 않아 상세 점검이 불가능합니다."
            $color = "Yellow"
        } else {
            $zones = Get-DnsServerZone | Where-Object { $_.IsReverseLookupZone -eq $false -and $_.ZoneType -ne "Forwarder" }
            $vulnerableZones = @()

            foreach ($zone in $zones) {
                # SecureSecondaries 값 분석
                # 0: 모든 서버에 전송 허용 (취약)
                # 1: 네임 서버(NS) 탭의 서버에만 허용 (양호/보통)
                # 2: 지정된 IP 주소로만 허용 (양호)
                # 3: 전송 허용 안 함 (양호)
                
                if ($zone.SecureSecondaries -eq "NoTransfer") {
                    continue # 양호
                } elseif ($zone.SecureSecondaries -eq "TransferAnyServer") {
                    $vulnerableZones += "$($zone.ZoneName)(모든 서버 허용)"
                } elseif ($zone.SecureSecondaries -eq "TransferNameServer" -or $zone.SecureSecondaries -eq "TransferSpecificHosts") {
                    # 특정 서버 제한이므로 양호로 간주
                    continue
                }
            }

            if ($vulnerableZones.Count -gt 0) {
                $result = "취약"
                $status = "다음 영역에서 모든 서버에 대한 영역 전송이 허용되어 있습니다: " + ($vulnerableZones -join ", ")
                $color = "Red"
            } else {
                $result = "양호"
                $status = "모든 DNS 영역의 영역 전송 설정이 안전하게(제한됨 또는 허용 안 함) 구성되어 있습니다."
                $color = "Green"
            }
        }
    }
} catch {
    $result = "오류"
    $status = "점검 중 에러 발생: $($_.Exception.Message)"
    $color = "Yellow"
}

# 4. 결과 객체 생성
$report = [PSCustomObject]@{
    "Category"       = $category
    "Code"           = $code
    "Risk Level"     = $riskLevel
    "Diagnosis Item" = $diagnosisItem
    "Result"         = $result
    "Current Status" = $status
    "Remedial Action"= $remedialAction
}

# 5. 콘솔 출력 및 CSV 저장
Write-Host "[결과] : $result" -ForegroundColor $color
Write-Host "[현황] : $status"
Write-Host "------------------------------------------------"

$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray