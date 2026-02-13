# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "SNMP_Service_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-29"
$riskLevel = "중"
$diagnosisItem = "불필요한 SNMP 서비스 구동 점검"
$remedialAction = "SNMP 서비스 미사용 시 서비스 중지 및 '사용 안 함' 설정 (필요 시 Community String 강화)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] SNMP 서비스 구동 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 3-1. SNMP 서비스(SNMP) 정보 가져오기
    $snmpSvc = Get-Service -Name "SNMP" -ErrorAction SilentlyContinue
    
    if ($null -eq $snmpSvc) {
        $result = "양호"
        $statusMsg = "시스템에 SNMP 서비스가 설치되어 있지 않습니다."
        $color = "Green"
    } else {
        # 시작 유형 확인 (Get-CimInstance 사용)
        $startType = (Get-CimInstance Win32_Service -Filter "Name='SNMP'").StartMode
        $currentStatus = $snmpSvc.Status

        # 3-2. 판정 로직
        # 서비스가 실행 중이거나 시작 유형이 'Disabled'가 아닌 경우 (취약 후보)
        if ($currentStatus -eq "Running" -or $startType -ne "Disabled") {
            # 실제 현업에서는 NMS 사용 여부를 확인해야 하므로 '취약'으로 판정 후 검토 권고
            $result = "취약"
            $statusMsg = "SNMP 서비스가 활성화되어 있습니다. (상태: $currentStatus, 시작유형: $startType). 업무상 필요 여부를 확인하십시오."
            $color = "Red"
        } else {
            $result = "양호"
            $statusMsg = "SNMP 서비스가 설치되어 있으나 중지 및 비활성화(Disabled) 상태입니다."
            $color = "Green"
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