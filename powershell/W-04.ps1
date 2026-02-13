# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Account_Lockout_Threshold_Check.csv"

# 2. 진단 정보 기본 설정
$category = "계정관리"
$code = "W-04"
$riskLevel = "상"
$diagnosisItem = "계정 잠금 임계값 설정"
$remedialAction = "계정 잠금 임계값을 '5회 이하'로 설정 (secpol.msc)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 계정 잠금 임계값 설정 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직 (보안 정책 내보내기 및 분석)
try {
    # 보안 정책을 임시 파일로 내보냄 (언어 설정에 무관하게 정확한 값 추출 가능)
    $tempFile = [System.IO.Path]::GetTempFileName()
    secedit /export /cfg $tempFile /areas SECURITYPOLICY | Out-Null
    
    # 내보낸 파일에서 LockoutBadCount(계정 잠금 임계값) 검색
    $policyContent = Get-Content $tempFile -Encoding Unicode
    $thresholdLine = $policyContent | Select-String "LockoutBadCount"
    
    if ($thresholdLine) {
        $threshold = [int]($thresholdLine.ToString().Split("=")[1].Trim())
        
        # 판정 로직: 0회는 잠금 기능을 사용하지 않으므로 취약, 5회 초과도 취약
        if ($threshold -eq 0) {
            $result = "취약"
            $status = "계정 잠금 임계값이 설정되지 않았습니다(0회)."
            $color = "Red"
        } elseif ($threshold -gt 5) {
            $result = "취약"
            $status = "계정 잠금 임계값이 5회를 초과하여 설정되어 있습니다($threshold회)."
            $color = "Red"
        } else {
            $result = "양호"
            $status = "계정 잠금 임계값이 적절하게 설정되어 있습니다($threshold회)."
            $color = "Green"
        }
    } else {
        $result = "취약"
        $status = "계정 잠금 정책 정보를 확인할 수 없습니다."
        $color = "Red"
    }

    # 임시 파일 삭제
    if (Test-Path $tempFile) { Remove-Item $tempFile }
} catch {
    $result = "오류"
    $status = "보안 정책을 분석하는 중 에러가 발생했습니다: $($_.Exception.Message)"
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

# CSV 저장 (UTF8 적용)
$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray