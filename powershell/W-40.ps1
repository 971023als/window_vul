# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Audit_Policy_Check.csv"

# 2. 진단 정보 기본 설정
$category = "로그 관리"
$code = "W-40"
$riskLevel = "중"
$diagnosisItem = "정책에 따른 시스템 로깅 설정"
$remedialAction = "로컬 보안 정책(secpol.msc)에서 권고된 감사 정책(성공/실패)을 설정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 시스템 로깅 설정 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # auditpol 결과를 가져옴 (언어 호환성을 위해 카테고리별로 확인)
    $auditStatus = auditpol /get /category:*
    
    $vulnerableItems = @()
    
    # 점검 대상 범주 및 권고 설정 정의
    # (일반적인 보안 가이드라인 기준: 주요 항목은 성공/실패 모두 기록)
    $checkList = @(
        @{ Name = "계정 로그온 이벤트"; Pattern = "Account Logon"; Recommendation = "성공 및 실패" },
        @{ Name = "계정 관리"; Pattern = "Account Management"; Recommendation = "성공 및 실패" },
        @{ Name = "로그온 이벤트"; Pattern = "Logon"; Recommendation = "성공 및 실패" },
        @{ Name = "정책 변경"; Pattern = "Policy Change"; Recommendation = "성공 및 실패" },
        @{ Name = "권한 사용"; Pattern = "Privilege Use"; Recommendation = "실패" }
    )

    foreach ($item in $checkList) {
        # 한국어/영어 환경 대응을 위해 auditpol 결과에서 해당 패턴 라인 추출
        $line = $auditStatus | Where-Object { $_ -match $item.Pattern -or $_ -match $item.Name }
        
        if ($null -eq $line) {
            $vulnerableItems += "$($item.Name): 설정 확인 불가"
            continue
        }

        # 권고 설정에 따른 검증
        if ($item.Recommendation -eq "성공 및 실패") {
            if ($line -notmatch "성공" -or $line -notmatch "실패" -and $line -notmatch "Success" -or $line -notmatch "Failure") {
                if ($line -notmatch "성공 및 실패" -and $line -notmatch "Success and Failure") {
                    $vulnerableItems += "$($item.Name): 현재($line)"
                }
            }
        } elseif ($item.Recommendation -eq "실패") {
            if ($line -notmatch "실패" -and $line -notmatch "Failure") {
                $vulnerableItems += "$($item.Name): 현재($line)"
            }
        }
    }

    # 4. 최종 결과 판정
    if ($vulnerableItems.Count -gt 0) {
        $result = "취약"
        $statusMsg = "다음 감사 정책이 권고 기준에 미달합니다: " + ($vulnerableItems -join " / ")
        $color = "Red"
    } else {
        $result = "양호"
        $statusMsg = "모든 주요 감사 정책이 권고 기준(성공/실패)에 따라 적절히 설정되어 있습니다."
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