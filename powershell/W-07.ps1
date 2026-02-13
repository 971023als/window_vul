# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Everyone_Anonymous_Access_Check.csv"

# 2. 진단 정보 기본 설정
$category = "계정관리"
$code = "W-07"
$riskLevel = "중"
$diagnosisItem = "Everyone 사용 권한을 익명 사용자에 적용"
$remedialAction = "'Everyone 사용 권한을 익명 사용자에게 적용' 정책을 '사용 안 함'으로 설정 (secpol.msc)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] Everyone 익명 적용 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직 (레지스트리 값 확인)
try {
    # 레지스트리 경로 및 값 설정
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    $regName = "EveryoneIncludesAnonymous"
    
    if (Test-Path $regPath) {
        $regValue = (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue).$regName
        
        # 레지스트리 값이 없으면 기본적으로 '사용 안 함'인 경우가 많으나 명시적 확인 필요
        if ($null -eq $regValue) {
            $result = "양호"
            $status = "정책 설정이 발견되지 않았습니다 (기본값: 사용 안 함)."
            $color = "Green"
        } elseif ($regValue -eq 1) {
            $result = "취약"
            $status = "정책이 '사용(Enabled)'으로 설정되어 익명 사용자의 접근이 허용된 상태입니다."
            $color = "Red"
        } else {
            $result = "양호"
            $status = "정책이 '사용 안 함(Disabled)'으로 적절히 설정되어 있습니다."
            $color = "Green"
        }
    } else {
        $result = "오류"
        $status = "레지스트리 경로를 찾을 수 없습니다."
        $color = "Yellow"
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