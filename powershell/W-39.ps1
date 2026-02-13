# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Antivirus_Update_Check.csv"

# 2. 진단 정보 기본 설정
$category = "패치 관리"
$code = "W-39"
$riskLevel = "상"
$diagnosisItem = "백신 프로그램 업데이트"
$remedialAction = "백신 엔진 및 패턴 파일을 최신으로 업데이트하고 실시간 감시 활성화"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 백신 프로그램 업데이트 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    $isVulnerable = $false
    $statusMsg = ""
    
    # 3-1. Microsoft Defender 상태 확인 (가장 일반적인 경우)
    $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue

    if ($null -ne $defender) {
        $lastUpdate = $defender.AntivirusSignatureLastUpdated
        $engineVersion = $defender.AntivirusEngineVersion
        $realTimeProtection = $defender.RealTimeProtectionEnabled

        if ($null -eq $lastUpdate -or $lastUpdate -eq [DateTime]::MinValue) {
            $isVulnerable = $true
            $statusMsg = "Defender 업데이트 기록을 찾을 수 없습니다."
        } else {
            $daysSince = ((Get-Date) - $lastUpdate).Days
            
            # 판정 기준: 마지막 업데이트 이후 7일이 지났으면 취약으로 간주
            if ($daysSince -gt 7) {
                $isVulnerable = $true
                $statusMsg = "Defender 업데이트가 지연됨 ($daysSince 일 경과 / 마지막 업데이트: $lastUpdate)"
            } else {
                $statusMsg = "Defender 최신 상태 유지 중 (업데이트: $lastUpdate / 엔진: $engineVersion)"
            }

            if (-not $realTimeProtection) {
                $isVulnerable = $true
                $statusMsg += " [경고: 실시간 보호 꺼짐]"
            }
        }
    } else {
        # 3-2. 타사 백신 제품 확인 (WMI SecurityCenter2 활용 - 주로 Client OS)
        $avProducts = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName AntiVirusProduct -ErrorAction SilentlyContinue
        
        if ($null -eq $avProducts) {
            # 서버 OS의 경우 SecurityCenter2에 정보가 없을 수 있으므로 서비스 목록 확인
            $avServices = Get-Service | Where-Object { $_.DisplayName -match "V3|McAfee|Symantec|CrowdStrike|Sentinel|Trend Micro|AhnLab" }
            
            if ($null -eq $avServices) {
                $isVulnerable = $true
                $statusMsg = "설치된 백신 프로그램을 찾을 수 없거나 Defender가 비활성화되어 있습니다."
            } else {
                $result = "수동 확인"
                $statusMsg = "타사 백신이 감지되었습니다($($avServices.DisplayName -join ', ')). 해당 프로그램 내에서 업데이트 날짜를 확인하십시오."
                $color = "Yellow"
            }
        } else {
            $statusMsg = "타사 백신 감지: $($avProducts.displayName). 업데이트 상태를 수동으로 확인하십시오."
            $result = "수동 확인"
            $color = "Yellow"
        }
    }

    # 4. 최종 결과 판정
    if ($isVulnerable) {
        $result = "취약"
        $color = "Red"
    } elseif ($null -eq $result) {
        $result = "양호"
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