# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "DNS_Dynamic_Update_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-32"
$riskLevel = "중"
$diagnosisItem = "DNS 서비스 구동 점검 (동적 업데이트)"
$remedialAction = "DNS 영역 속성에서 '동적 업데이트'를 '없음'으로 설정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] DNS 동적 업데이트 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 3-1. DNS 서비스 존재 및 상태 확인
    $dnsService = Get-Service -Name "DNS" -ErrorAction SilentlyContinue
    
    if ($null -eq $dnsService -or $dnsService.Status -ne "Running") {
        $result = "양호"
        $statusMsg = "DNS 서비스가 설치되어 있지 않거나 중지 상태입니다."
        $color = "Green"
    } else {
        # 3-2. DNS 서버 모듈 확인 및 영역 정보 추출
        if (!(Get-Command Get-DnsServerZone -ErrorAction SilentlyContinue)) {
            $result = "오류"
            $statusMsg = "DNS 관리 도구가 설치되어 있지 않아 상세 점검이 불가능합니다."
            $color = "Yellow"
        } else {
            $zones = Get-DnsServerZone | Where-Object { $_.ZoneType -ne "Forwarder" }
            $vulnerableZones = @()

            foreach ($zone in $zones) {
                # DynamicUpdate 값 분석
                # None: 업데이트 없음 (양호)
                # Secure: 보안 동적 업데이트만 (취약 - 가이드라인 기준)
                # NonSecureAndSecure: 모든 동적 업데이트 (취약)
                
                if ($zone.DynamicUpdate -ne "None") {
                    $vulnerableZones += "$($zone.ZoneName)($($zone.DynamicUpdate))"
                }
            }

            if ($vulnerableZones.Count -gt 0) {
                $result = "취약"
                $statusMsg = "다음 영역에서 동적 업데이트가 활성화되어 있습니다: " + ($vulnerableZones -join ", ")
                $color = "Red"
            } else {
                $result = "양호"
                $statusMsg = "모든 DNS 영역의 동적 업데이트가 '없음(None)'으로 설정되어 있습니다."
                $color = "Green"
            }
        }
    }
} catch {
    $result = "오류"
    $statusMsg = "점검 중 에러 발생: $($_.Exception.Message)"
    $color = "Yellow"
}

# 4. 결과 객체 생성
$report = [PSCustomObject]@{
    "Category"       = $category
    "Code"           = $code
    "Risk Level"     = $riskLevel
    "Diagnosis Item" = $diagnosisItem
    "Result"         = $result
    "Current Status" = $statusMsg
    "Remedial Action"= $remedialAction
}

# 5. 콘솔 출력 및 CSV 저장
Write-Host "[결과] : $result" -ForegroundColor $color
Write-Host "[현황] : $statusMsg"
Write-Host "------------------------------------------------"

$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray