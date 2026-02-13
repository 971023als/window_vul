# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Secure_Channel_Encryption_Check.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-60"
$riskLevel = "중"
$diagnosisItem = "보안 채널 데이터 디지털 암호화 또는 서명"
$remedialAction = "보안 옵션 내 도메인 구성원 관련 보안 채널 암호화/서명 3개 항목을 모두 '사용'으로 설정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 보안 채널 데이터 암호화 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 레지스트리 경로: HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters"
    
    $isVulnerable = $false
    $statusMsg = ""

    if (Test-Path $regPath) {
        $regValues = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
        
        # 3-1. 정책별 레지스트리 값 매핑
        # 1: 항상 암호화 또는 서명 (RequireSignOrSeal)
        # 2: 가능한 경우 암호화 (SealSecureChannel)
        # 3: 가능한 경우 서명 (SignSecureChannel)
        
        $requireSignOrSeal = $regValues.RequireSignOrSeal
        $sealSecureChannel = $regValues.SealSecureChannel
        $signSecureChannel = $regValues.SignSecureChannel

        $details = @()

        # 4. 판정 로직 (모두 1이어야 양호)
        if ($requireSignOrSeal -ne 1) { 
            $isVulnerable = $true 
            $details += "암호화 또는 서명(항상): 미사용"
        }
        if ($sealSecureChannel -ne 1) { 
            $isVulnerable = $true 
            $details += "디지털 암호화(가능한 경우): 미사용"
        }
        if ($signSecureChannel -ne 1) { 
            $isVulnerable = $true 
            $details += "디지털 서명(가능한 경우): 미사용"
        }

        if ($isVulnerable) {
            $result = "취약"
            $statusMsg = "다음 정책이 설정되어 있지 않습니다: " + ($details -join ", ")
            $color = "Red"
        } else {
            $result = "양호"
            $statusMsg = "모든 보안 채널 암호화 및 서명 정책이 '사용'으로 설정되어 있습니다."
            $color = "Green"
        }
    } else {
        $result = "오류"
        $statusMsg = "Netlogon 레지스트리 경로를 찾을 수 없습니다."
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