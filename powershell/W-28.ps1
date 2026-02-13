# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "RDP_Encryption_Level_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-28"
$riskLevel = "중"
$diagnosisItem = "터미널 서비스 암호화 수준 설정"
$remedialAction = "RDP 암호화 수준을 '클라이언트와 호환 가능(2)' 또는 '높음(3)'으로 설정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 터미널 서비스 암호화 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 3-1. 원격 데스크톱 서비스(RDP) 활성화 여부 확인
    # fDenyTSConnections: 0(허용), 1(거부)
    $tsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
    $isDenied = (Get-ItemProperty -Path $tsPath -Name "fDenyTSConnections" -ErrorAction SilentlyContinue).fDenyTSConnections

    if ($isDenied -eq 1) {
        $result = "양호"
        $statusMsg = "원격 데스크톱 서비스가 비활성화(사용 안 함) 상태입니다."
        $color = "Green"
    } else {
        # 3-2. 암호화 수준(MinEncryptionLevel) 확인
        # 1: 낮음, 2: 클라이언트와 호환 가능(중간), 3: 높음, 4: FIPS 규격
        $rdpTcpPath = "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
        $encLevel = (Get-ItemProperty -Path $rdpTcpPath -Name "MinEncryptionLevel" -ErrorAction SilentlyContinue).MinEncryptionLevel

        if ($null -eq $encLevel) {
            # 값이 없는 경우 기본값(보통 2 이상)으로 동작하나, 명시적이지 않으므로 확인 필요
            $result = "취약"
            $statusMsg = "RDP 암호화 수준 레지스트리 값이 존재하지 않습니다."
            $color = "Red"
        } elseif ($encLevel -ge 2) {
            $result = "양호"
            $levelText = switch($encLevel) {
                2 { "클라이언트와 호환 가능(중간)" }
                3 { "높음" }
                4 { "FIPS 규격" }
                Default { "정의되지 않은 높은 수준($encLevel)" }
            }
            $statusMsg = "RDP 암호화 수준이 '$levelText'으로 적절히 설정되어 있습니다."
            $color = "Green"
        } else {
            $result = "취약"
            $statusMsg = "RDP 암호화 수준이 '낮음(1)'으로 설정되어 데이터 노출 위험이 있습니다."
            $color = "Red"
        }
    }
} catch {
    $result = "오류"
    $statusMsg = "점검 중 에러 발생: $($_.Exception.Message)"
    $color = "Yellow"
}

# 4. 결과 객체 생성
$report = [PSCustomObject]@{
    "Category"       = $category
    "Code"           = $code
    "Risk Level"     = $riskLevel
    "Diagnosis Item" = $diagnosisItem
    "Result"         = $result
    "Current Status" = $statusMsg
    "Remedial Action"= $remedialAction
}

# 5. 콘솔 출력 및 CSV 저장
Write-Host "[결과] : $result" -ForegroundColor $color
Write-Host "[현황] : $statusMsg"
Write-Host "------------------------------------------------"

$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray