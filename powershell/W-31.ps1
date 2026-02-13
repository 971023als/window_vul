# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "SNMP_Access_Control_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-31"
$riskLevel = "중"
$diagnosisItem = "SNMP Access Control 설정"
$remedialAction = "SNMP 보안 설정에서 '다음 호스트로부터 SNMP 패킷 받아들이기'를 선택하고 관리 서버 IP 등록"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] SNMP Access Control 점검 시작" -ForegroundColor Cyan
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
        # 3-2. 레지스트리에서 허용된 호스트(PermittedManagers) 확인
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers"
        
        if (Test-Path $regPath) {
            $managers = Get-ItemProperty -Path $regPath
            # 기본 속성을 제외한 실제 등록된 호스트 목록 추출
            $managerList = $managers.PSObject.Properties.Name | Where-Object { 
                $_ -notmatch "PSPath|PSParentPath|PSChildName|PSDrive|PSProvider" 
            }

            if ($null -eq $managerList -or $managerList.Count -eq 0) {
                # 등록된 호스트가 없으면 '모든 호스트 허용' 상태로 간주 (취약)
                $result = "취약"
                $statusMsg = "허용된 SNMP 호스트(IP)가 등록되어 있지 않습니다. (모든 호스트 허용 상태)"
                $color = "Red"
            } else {
                # 특정 호스트 값이 존재하면 양호
                $hosts = @()
                foreach ($m in $managerList) {
                    $hosts += $managers.$m
                }
                $result = "양호"
                $statusMsg = "특정 호스트로부터만 패킷을 수용하도록 설정되어 있습니다. (허용된 IP: $($hosts -join ', '))"
                $color = "Green"
            }
        } else {
            # 서비스는 있으나 매니저 설정 키가 없는 경우 (일반적으로 모든 호스트 허용 상태)
            $result = "취약"
            $statusMsg = "SNMP 호스트 접근 제어 설정(PermittedManagers)이 구성되지 않았습니다."
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