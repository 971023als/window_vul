# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Antivirus_Installation_Check.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-45"
$riskLevel = "상"
$diagnosisItem = "백신 프로그램 설치"
$remedialAction = "바이러스 백신 프로그램 설치 및 실시간 감시 활성화"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 백신 프로그램 설치 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    $avInstalled = $false
    $avList = @()

    # 3-1. Microsoft Defender 서비스 확인 (가장 일반적)
    $defenderSvc = Get-Service -Name "WinDefend" -ErrorAction SilentlyContinue
    if ($null -ne $defenderSvc -and $defenderSvc.Status -eq "Running") {
        $avInstalled = $true
        $avList += "Microsoft Defender (Running)"
    }

    # 3-2. 주요 타사 백신 서비스 패턴 확인
    # AhnLab(V3), Symantec, McAfee, Trend Micro, Kaspersky, CrowdStrike, SentinelOne 등
    $commonAVPatterns = "V3|AhnLab|Symantec|EndpointProtection|McAfee|McShield|rtvscan|TMListen|ksv|CSAgent|Sentinel"
    $thirdPartyAV = Get-Service | Where-Object { $_.Name -match $commonAVPatterns -or $_.DisplayName -match $commonAVPatterns }

    if ($null -ne $thirdPartyAV) {
        foreach ($av in $thirdPartyAV) {
            if ($av.Status -eq "Running") {
                $avInstalled = $true
                $avList += "$($av.DisplayName) (Running)"
            }
        }
    }

    # 4. 판정 로직
    if ($avInstalled) {
        $result = "양호"
        $statusMsg = "백신 프로그램이 설치되어 있으며 정상 구동 중입니다. (감지된 제품: " + ($avList -join ", ") + ")"
        $color = "Green"
    } else {
        # 설치는 되어있으나 중지된 경우인지, 아예 없는 경우인지 상세 구분
        $stoppedAV = Get-Service | Where-Object { $_.Name -match $commonAVPatterns -or $_.Name -eq "WinDefend" }
        if ($null -ne $stoppedAV) {
            $result = "취약"
            $statusMsg = "백신 프로그램이 설치되어 있으나 현재 중지 상태입니다. (대상: " + ($stoppedAV.DisplayName -join ", ") + ")"
            $color = "Red"
        } else {
            $result = "취약"
            $statusMsg = "시스템에서 실행 중인 백신 프로그램을 찾을 수 없습니다."
            $color = "Red"
        }
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