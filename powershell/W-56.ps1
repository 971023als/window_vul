# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "SMB_Session_Management_Check.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-56"
$riskLevel = "중"
$diagnosisItem = "SMB 세션 중단 관리 설정"
$remedialAction = "보안 옵션에서 '로그온 시간 만료 시 클라이언트 연결 끊기'를 사용으로, '유휴 시간'을 15분 이하로 설정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] SMB 세션 중단 설정 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 레지스트리 경로: HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
    
    $isVulnerable = $false
    $statusMsg = ""

    if (Test-Path $regPath) {
        $regValues = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
        
        # 3-1. 로그온 시간 만료 시 연결 끊기 (enableforcedlogoff)
        # 1: 사용(양호), 0: 사용 안 함(취약)
        $forceLogoff = $regValues.enableforcedlogoff
        
        # 3-2. 세션 연결 중단 전 유휴 시간 (autodisconnect)
        # 단위: 분 (15분 이하 양호)
        $autoDisconnect = $regValues.autodisconnect

        # 4. 판정 로직
        $check1 = $false
        $check2 = $false

        # 정책 1 검증
        if ($forceLogoff -eq 1) {
            $check1 = $true
        } else {
            $statusMsg += "[정책1: 로그온 만료 시 연결 끊기 미설정] "
        }

        # 정책 2 검증
        if ($null -ne $autoDisconnect -and $autoDisconnect -le 15) {
            $check2 = $true
        } else {
            $currentIdle = if ($null -eq $autoDisconnect) { "설정없음" } else { "$autoDisconnect 분" }
            $statusMsg += "[정책2: 유휴 시간 15분 초과 또는 미설정(현재: $currentIdle)]"
        }

        # 최종 판정: 두 정책 모두 만족해야 양호
        if ($check1 -and $check2) {
            $result = "양호"
            $statusMsg = "두 정책 모두 권고 기준(사용, 15분 이하)을 준수하고 있습니다."
            $color = "Green"
        } else {
            $result = "취약"
            $color = "Red"
        }
    } else {
        $result = "오류"
        $statusMsg = "LanmanServer 레지스트리 경로를 찾을 수 없습니다."
        $color = "Yellow"
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