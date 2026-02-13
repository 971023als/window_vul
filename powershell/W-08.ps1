# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Account_Lockout_Duration_Check.csv"

# 2. 진단 정보 기본 설정
$category = "계정관리"
$code = "W-08"
$riskLevel = "중"
$diagnosisItem = "계정 잠금 기간 설정"
$remedialAction = "'계정 잠금 기간' 및 '계정 잠금 수를 원래대로 설정'을 60분 이상으로 설정 (secpol.msc)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 계정 잠금 기간 설정 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직 (보안 정책 분석)
try {
    # 보안 정책을 임시 파일로 내보냄
    $tempFile = [System.IO.Path]::GetTempFileName()
    secedit /export /cfg $tempFile /areas SECURITYPOLICY | Out-Null
    
    $policyContent = Get-Content $tempFile -Encoding Unicode
    
    # LockoutDuration (계정 잠금 기간)
    $durationLine = $policyContent | Select-String "LockoutDuration"
    # ResetLockoutCount (계정 잠금 수를 원래대로 설정 기간)
    $resetLine = $policyContent | Select-String "ResetLockoutCount"
    
    if ($durationLine -and $resetLine) {
        $duration = [int]($durationLine.ToString().Split("=")[1].Trim())
        $reset = [int]($resetLine.ToString().Split("=")[1].Trim())
        
        # 판정 로직: 둘 다 60분 이상이어야 양호
        if ($duration -ge 60 -and $reset -ge 60) {
            $result = "양호"
            $status = "계정 잠금 기간($duration분) 및 원래대로 설정 기간($reset분)이 모두 60분 이상입니다."
            $color = "Green"
        } else {
            $result = "취약"
            $status = "설정값이 60분 미만입니다. (잠금 기간: $duration분, 원래대로 설정: $reset분)"
            $color = "Red"
        }
    } else {
        $result = "취약"
        $status = "계정 잠금 정책이 설정되지 않았거나 정보를 확인할 수 없습니다."
        $color = "Red"
    }

    # 임시 파일 삭제
    if (Test-Path $tempFile) { Remove-Item $tempFile }
} catch {
    $result = "오류"
    $status = "보안 정책 분석 중 오류 발생: $($_.Exception.Message)"
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

# CSV 저장 (Append 모드)
$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray