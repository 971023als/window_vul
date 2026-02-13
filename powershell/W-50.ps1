# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Audit_Shutdown_Policy_Check.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-50"
$riskLevel = "상"
$diagnosisItem = "보안 감사를 로그 할 수 없는 경우 즉시 시스템 종료"
$remedialAction = "보안 옵션에서 '감사: 보안 감사를 기록할 수 없는 경우 즉시 시스템 종료'를 '사용 안 함'으로 설정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 보안 감사 로그 실패 시 종료 정책 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 레지스트리 경로: HKLM\SYSTEM\CurrentControlSet\Control\Lsa
    # 값 이름: crashonauditfail
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    $valueName = "crashonauditfail"
    
    $isVulnerable = $false
    $statusMsg = ""

    if (Test-Path $regPath) {
        $regValue = (Get-ItemProperty -Path $regPath -Name $valueName -ErrorAction SilentlyContinue).$valueName
        
        # 4. 판정 로직
        # 0: 사용 안 함 (양호)
        # 1: 사용 (취약)
        # 2: 정책에 의해 시스템이 이미 종료된 적이 있음 (취약/조치 필요)
        
        if ($null -eq $regValue -or $regValue -eq 0) {
            $result = "양호"
            $statusMsg = "정책이 '사용 안 함(0)'으로 적절히 설정되어 있습니다."
            $color = "Green"
        } elseif ($regValue -eq 1) {
            $isVulnerable = $true
            $result = "취약"
            $statusMsg = "정책이 '사용(1)'으로 설정되어 있어 DoS 공격 위험이 있습니다."
            $color = "Red"
        } elseif ($regValue -eq 2) {
            $isVulnerable = $true
            $result = "취약"
            $statusMsg = "정책이 활성화되어 있으며, 과거에 로그 부족으로 시스템이 종료된 이력이 있습니다(값:2)."
            $color = "Red"
        }
    } else {
        $result = "오류"
        $statusMsg = "해당 레지스트리 경로를 찾을 수 없습니다."
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