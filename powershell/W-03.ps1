# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Unnecessary_Account_Check.csv"

# 2. 진단 정보 기본 설정
$category = "계정관리"
$code = "W-03"
$riskLevel = "상"
$diagnosisItem = "불필요한 계정 제거"
$remedialAction = "사용하지 않는 퇴사자/테스트 계정 삭제 또는 '계정 사용 안 함' 처리 (lusrmgr.msc)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 불필요한 계정 제거 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 점검 기준 설정 (90일 미접속 기준)
$thresholdDays = 90
$thresholdDate = (Get-Date).AddDays(-$thresholdDays)
$suspiciousAccounts = @()

# 4. 실제 점검 로직
try {
    # 모든 로컬 계정 가져오기
    $allUsers = Get-LocalUser

    foreach ($user in $allUsers) {
        # 시스템 빌트인/필수 계정은 제외 (RID 500, 501, WDAGUtilityAccount 등 제외 로직)
        # SID 패턴으로 빌트인 관리자(-500), 게스트(-501)는 W-01, W-02에서 점검하므로 여기서도 제외 가능
        if ($user.SID.Value -like "*-500" -or $user.SID.Value -like "*-501" -or $user.Name -eq "DefaultAccount" -or $user.Name -eq "WDAGUtilityAccount") {
            continue
        }

        $reason = ""
        # 기준 1: 장기간 미접속 (로그인 기록이 있고, 기준일보다 이전인 경우)
        if ($user.LastLogon -and $user.LastLogon -lt $thresholdDate) {
            $reason = "$thresholdDays일 이상 미접속"
        }
        # 기준 2: 로그인 기록이 아예 없는 계정 (생성 후 방치 가능성)
        elseif (-not $user.LastLogon) {
            $reason = "로그인 기록 없음"
        }
        # 기준 3: 이름에 test, temp 등 의심스러운 키워드 포함
        if ($user.Name -match "test|temp|guest") {
            $reason += " [의심스러운 이름]"
        }

        if ($reason -ne "") {
            $suspiciousAccounts += "$($user.Name)($reason)"
        }
    }

    if ($suspiciousAccounts.Count -gt 0) {
        $result = "취약"
        $status = "불필요하거나 의심스러운 계정이 발견되었습니다: " + ($suspiciousAccounts -join ", ")
        $color = "Red"
    } else {
        $result = "양호"
        $status = "장기 미접속 계정이나 의심스러운 테스트 계정이 발견되지 않았습니다."
        $color = "Green"
    }
} catch {
    $result = "오류"
    $status = "계정 정보를 가져오는 중 에러가 발생했습니다: $($_.Exception.Message)"
    $color = "Yellow"
}

# 5. 결과 객체 생성
$report = [PSCustomObject]@{
    "Category"       = $category
    "Code"           = $code
    "Risk Level"     = $riskLevel
    "Diagnosis Item" = $diagnosisItem
    "Result"         = $result
    "Current Status" = $status
    "Remedial Action"= $remedialAction
}

# 6. 콘솔 출력 및 CSV 저장
Write-Host "[결과] : $result" -ForegroundColor $color
Write-Host "[현황] : $status"
Write-Host "------------------------------------------------"

# CSV 저장 (Append 모드)
$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray