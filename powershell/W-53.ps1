# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Removable_Media_Control_Check.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-53"
$riskLevel = "상"
$diagnosisItem = "이동식 미디어 포맷 및 꺼내기 허용"
$remedialAction = "보안 옵션에서 '장치: 이동식 미디어 포맷 및 꺼내기 허용'을 'Administrators'로 설정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 이동식 미디어 권한 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 레지스트리 경로: HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon
    # 값 이름: AllocateDASD
    # 0: Administrators, 1: Administrators and Power Users, 2: Administrators and Interactive Users
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    $valueName = "AllocateDASD"
    
    $isVulnerable = $false
    $statusMsg = ""

    if (Test-Path $regPath) {
        $regValue = (Get-ItemProperty -Path $regPath -Name $valueName -ErrorAction SilentlyContinue).$valueName
        
        # 4. 판정 로직
        if ($regValue -eq "0") {
            $result = "양호"
            $statusMsg = "권한이 'Administrators(0)' 그룹으로 적절히 제한되어 있습니다."
            $color = "Green"
        } elseif ($regValue -eq "1") {
            $isVulnerable = $true
            $statusMsg = "권한이 'Administrators 및 Power Users(1)'에게 부여되어 있습니다."
        } elseif ($regValue -eq "2") {
            $isVulnerable = $true
            $statusMsg = "권한이 'Administrators 및 Interactive Users(2)'에게 부여되어 있습니다."
        } else {
            # 값이 명시되지 않은 경우 (기본값은 0이나 안전을 위해 확인 권고)
            $result = "양호"
            $statusMsg = "레지스트리 값이 설정되어 있지 않으나 기본값(0)으로 동작 중입니다."
            $color = "Green"
        }

        if ($isVulnerable) {
            $result = "취약"
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