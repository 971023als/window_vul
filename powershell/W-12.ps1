# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Anonymous_SID_Translation_Check.csv"

# 2. 진단 정보 기본 설정
$category = "계정관리"
$code = "W-12"
$riskLevel = "중"
$diagnosisItem = "익명 SID/이름 변환 허용 해제"
$remedialAction = "'네트워크 액세스: 익명 SID/이름 변환 허용' 정책을 '사용 안 함'으로 설정 (secpol.msc)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 익명 SID/이름 변환 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직 (레지스트리 값 확인)
try {
    # 레지스트리 경로 및 값 설정
    $regPath = "HKLM:\System\CurrentControlSet\Control\Lsa"
    $regName = "LsaAnonymousNameLookup"
    
    if (Test-Path $regPath) {
        $regValue = (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue).$regName
        
        # 레지스트리 값이 1이면 허용(취약)
        # 레지스트리 값이 0이면 허용 안 함(양호)
        if ($regValue -eq 1) {
            $result = "취약"
            $status = "정책이 '사용(Enabled)'으로 설정되어 익명 사용자의 SID/이름 변환이 허용된 상태입니다."
            $color = "Red"
        } else {
            $result = "양호"
            $status = "정책이 '사용 안 함(Disabled)'으로 적절히 설정되어 있습니다."
            $color = "Green"
        }
    } else {
        # 레지스트리 값이 없는 경우 기본적으로 0(Disabled)으로 작동함
        $result = "양호"
        $status = "관련 레지스트리 설정이 발견되지 않았습니다 (기본값: Disabled)."
        $color = "Green"
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