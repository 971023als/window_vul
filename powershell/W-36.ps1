# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "RDP_Timeout_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-36"
$riskLevel = "중"
$diagnosisItem = "원격터미널 접속 타임아웃 설정"
$remedialAction = "유휴 세션 제한 시간을 '30분' 이하로 설정 (그룹 정책 또는 레지스트리)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] RDP 타임아웃 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 3-1. RDP 활성화 여부 확인 (fDenyTSConnections: 0은 사용 중)
    $tsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
    $isDenied = (Get-ItemProperty -Path $tsPath -Name "fDenyTSConnections" -ErrorAction SilentlyContinue).fDenyTSConnections

    # 3-2. 타임아웃 설정값(MaxIdleTime) 확인
    # 정책 우선순위: 그룹 정책(Policies) > 로컬 설정(WinStations)
    $regPathPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
    $regPathLocal = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
    
    $maxIdleTime = $null
    
    # 그룹 정책 확인
    if (Test-Path $regPathPolicy) {
        $maxIdleTime = (Get-ItemProperty -Path $regPathPolicy -Name "MaxIdleTime" -ErrorAction SilentlyContinue).MaxIdleTime
    }
    
    # 그룹 정책에 없으면 로컬 설정 확인
    if ($null -eq $maxIdleTime -and (Test-Path $regPathLocal)) {
        $maxIdleTime = (Get-ItemProperty -Path $regPathLocal -Name "MaxIdleTime" -ErrorAction SilentlyContinue).MaxIdleTime
    }

    # 4. 판정 로직 (30분 = 1,800,000 ms)
    $timeoutLimit = 1800000 

    if ($isDenied -eq 1) {
        $result = "양호"
        $statusMsg = "원격 데스크톱 서비스가 비활성화 상태입니다."
        $color = "Green"
    } elseif ($null -eq $maxIdleTime -or $maxIdleTime -eq 0) {
        $result = "취약"
        $statusMsg = "유휴 세션 제한 시간이 설정되어 있지 않습니다. (무제한)"
        $color = "Red"
    } elseif ($maxIdleTime -gt $timeoutLimit) {
        $min = $maxIdleTime / 60000
        $result = "취약"
        $statusMsg = "유휴 세션 제한 시간이 30분을 초과하여 설정되어 있습니다. (현재: $min 분)"
        $color = "Red"
    } else {
        $min = $maxIdleTime / 60000
        $result = "양호"
        $statusMsg = "유휴 세션 제한 시간이 $min 분으로 적절히 설정되어 있습니다."
        $color = "Green"
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