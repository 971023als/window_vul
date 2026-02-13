# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Printer_Driver_Installation_Check.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-55"
$riskLevel = "중"
$diagnosisItem = "사용자가 프린터 드라이버를 설치할 수 없게 함"
$remedialAction = "보안 옵션에서 '장치: 사용자가 프린터 드라이버를 설치할 수 없게 함'을 '사용'으로 설정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 프린터 드라이버 설치 제한 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 레지스트리 경로: HKLM\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers
    # 값 이름: AddPrinterDrivers
    # 1: 사용(Administrators만 설치 가능 / 양호)
    # 0: 사용 안 함(일반 사용자도 설치 가능 / 취약)
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers"
    $valueName = "AddPrinterDrivers"
    
    $isVulnerable = $false
    $statusMsg = ""

    if (Test-Path $regPath) {
        $regValue = (Get-ItemProperty -Path $regPath -Name $valueName -ErrorAction SilentlyContinue).$valueName
        
        # 4. 판정 로직
        if ($regValue -eq 1) {
            $result = "양호"
            $statusMsg = "정책이 '사용(1)'으로 설정되어 관리자만 드라이버를 설치할 수 있습니다."
            $color = "Green"
        } elseif ($regValue -eq 0) {
            $isVulnerable = $true
            $result = "취약"
            $statusMsg = "정책이 '사용 안 함(0)'으로 설정되어 일반 사용자도 드라이버 설치가 가능합니다."
            $color = "Red"
        } else {
            # 값이 아예 없는 경우 (기본값은 OS 버전에 따라 다르나 보안상 '사용' 설정을 권장)
            $isVulnerable = $true
            $result = "취약"
            $statusMsg = "해당 레지스트리 설정이 존재하지 않아 기본 보안 정책이 적용되지 않았을 수 있습니다."
            $color = "Red"
        }
    } else {
        $result = "오류"
        $statusMsg = "프린터 서비스 레지스트리 경로를 찾을 수 없습니다."
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