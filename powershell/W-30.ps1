# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "SNMP_Community_String_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-30"
$riskLevel = "중"
$diagnosisItem = "SNMP Community String 복잡성 설정"
$remedialAction = "기본 Community String(public, private) 제거 및 복잡한 문자열로 변경"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] SNMP Community String 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 3-1. SNMP 서비스 설치 여부 확인
    $snmpSvc = Get-Service -Name "SNMP" -ErrorAction SilentlyContinue
    
    if ($null -eq $snmpSvc) {
        $result = "양호"
        $statusMsg = "시스템에 SNMP 서비스가 설치되어 있지 않습니다."
        $color = "Green"
    } else {
        # 3-2. 레지스트리에서 유효한 커뮤니티 값 읽기
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities"
        
        if (Test-Path $regPath) {
            $communities = Get-ItemProperty -Path $regPath
            # 기본 속성(PSPath 등)을 제외한 실제 등록된 커뮤니티 이름만 추출
            $commNames = $communities.PSObject.Properties.Name | Where-Object { 
                $_ -notmatch "PSPath|PSParentPath|PSChildName|PSDrive|PSProvider" 
            }

            if ($null -eq $commNames -or $commNames.Count -eq 0) {
                $result = "양호"
                $statusMsg = "SNMP 서비스는 존재하나 등록된 Community String이 없습니다."
                $color = "Green"
            } else {
                # 취약한 기본 문자열 포함 여부 검사
                $vulnerableStrings = $commNames | Where-Object { $_ -ieq "public" -or $_ -ieq "private" }

                if ($vulnerableStrings) {
                    $result = "취약"
                    $statusMsg = "기본 Community String이 발견되었습니다: " + ($vulnerableStrings -join ", ")
                    $color = "Red"
                } else {
                    $result = "양호"
                    $statusMsg = "설정된 Community String이 기본값이 아니며 적절합니다. (설정된 개수: $($commNames.Count)개)"
                    $color = "Green"
                }
            }
        } else {
            # 서비스는 있으나 레지스트리 키가 없는 경우 (설정 미비)
            $result = "양호"
            $statusMsg = "SNMP 커뮤니티 설정이 구성되지 않았습니다."
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