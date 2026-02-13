# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Anonymous_Enumeration_Check.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-51"
$riskLevel = "상"
$diagnosisItem = "SAM 계정과 공유의 익명 열거 허용 안 함"
$remedialAction = "보안 옵션에서 '네트워크 액세스: SAM 계정과 공유의 익명 열거 허용 안 함'을 '사용'으로 설정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 익명 계정 열거 방지 설정 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 레지스트리 경로: HKLM\System\CurrentControlSet\Control\Lsa
    # 값 이름: RestrictAnonymousSAM (1: 허용 안 함/양호, 0: 허용/취약)
    $regPath = "HKLM:\System\CurrentControlSet\Control\Lsa"
    $valueName = "RestrictAnonymousSAM"
    
    $isVulnerable = $false
    $statusMsg = ""

    if (Test-Path $regPath) {
        $regValue = (Get-ItemProperty -Path $regPath -Name $valueName -ErrorAction SilentlyContinue).$valueName
        
        # 4. 판정 로직
        if ($regValue -eq 1) {
            $result = "양호"
            $statusMsg = "익명 열거 허용 안 함 정책이 '사용(1)'으로 적절히 설정되어 있습니다."
            $color = "Green"
        } elseif ($regValue -eq 0) {
            $isVulnerable = $true
            $result = "취약"
            $statusMsg = "익명 열거 허용 안 함 정책이 '사용 안 함(0)'으로 설정되어 정보 유출 위험이 있습니다."
            $color = "Red"
        } else {
            # 값이 아예 없는 경우 (현대 Windows Server 기본값은 1이나 명시적 설정 권장)
            $isVulnerable = $true
            $result = "취약"
            $statusMsg = "해당 레지스트리 값이 명시되어 있지 않습니다. (기본값 확인 필요)"
            $color = "Red"
        }
    } else {
        $result = "오류"
        $statusMsg = "Lsa 레지스트리 경로를 찾을 수 없습니다."
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