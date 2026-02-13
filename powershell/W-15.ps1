# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Private_Key_Protection_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-15"
$riskLevel = "상"
$diagnosisItem = "사용자 개인키 사용 시 암호 입력"
$remedialAction = "'시스템 암호화: 컴퓨터에 저장된 사용자 키에 대해 강력한 키 보호 사용'을 '매 번 입력'으로 설정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 사용자 개인키 암호 입력 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직 (레지스트리 값 확인)
try {
    # 레지스트리 경로 및 값 설정
    $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Cryptography"
    $regName = "ForceKeyProtection"
    
    if (Test-Path $regPath) {
        $regValue = (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue).$regName
        
        # 0: 사용자 입력 필요 없음 (취약)
        # 1: 처음 사용 시 사용자에게 프롬프트 표시 (취약 - 매번 입력 아님)
        # 2: 키를 사용할 때마다 암호 입력 필요 (양호)
        if ($regValue -eq 2) {
            $result = "양호"
            $status = "정책이 '키를 사용할 때마다 암호 입력(2)'으로 적절히 설정되어 있습니다."
            $color = "Green"
        } elseif ($regValue -eq 1) {
            $result = "취약"
            $status = "정책이 '처음 사용 시 프롬프트(1)'로 설정되어 있습니다. (매번 입력 필요)"
            $color = "Red"
        } else {
            $result = "취약"
            $status = "정책이 '암호 입력 없음(0)' 또는 설정되지 않아 개인키 도용 위험이 있습니다."
            $color = "Red"
        }
    } else {
        # 정책 경로 자체가 없는 경우 (기본값은 강력한 보호 미사용임)
        $result = "취약"
        $status = "강력한 키 보호 정책이 설정되어 있지 않습니다. (기본값: 취약)"
        $color = "Red"
    }
} catch {
    $result = "오류"
    $status = "점검 중 에러 발생: $($_.Exception.Message)"
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