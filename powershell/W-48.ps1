# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Shutdown_Without_Logon_Check.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-48"
$riskLevel = "상"
$diagnosisItem = "로그온하지 않고 시스템 종료 허용"
$remedialAction = "보안 옵션에서 '시스템 종료: 로그온하지 않고 시스템 종료 허용'을 '사용 안 함'으로 설정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 로그온 전 종료 허용 여부 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 레지스트리 경로 (로컬 보안 정책 반영 경로)
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    $valueName = "shutdownwithoutlogon"
    
    $isVulnerable = $false
    $statusMsg = ""

    # 레지스트리 값 존재 여부 확인
    if (Test-Path $regPath) {
        $regValue = (Get-ItemProperty -Path $regPath -Name $valueName -ErrorAction SilentlyContinue).$valueName
        
        # 4. 판정 로직
        # 0: 사용 안 함 (양호), 1: 사용 (취약)
        if ($null -eq $regValue) {
            # 기본값 확인: Windows Server 버전은 기본적으로 이 값이 0(사용 안 함)임
            $result = "양호"
            $statusMsg = "레지스트리 값이 명시되어 있지 않으나, 서버 기본값(사용 안 함)으로 동작 중입니다."
            $color = "Green"
        } elseif ($regValue -eq 1) {
            $isVulnerable = $true
            $result = "취약"
            $statusMsg = "로그온하지 않고 시스템 종료 허용이 '사용(1)'으로 설정되어 있습니다."
            $color = "Red"
        } else {
            $result = "양호"
            $statusMsg = "로그온하지 않고 시스템 종료 허용이 '사용 안 함(0)'으로 적절히 설정되어 있습니다."
            $color = "Green"
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