# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "RDS_Removal_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-26"
$riskLevel = "상"
$diagnosisItem = "RDS(Remote Data Services) 제거"
$remedialAction = "불필요한 MSADC 가상 디렉터리 제거 및 관련 레지스트리 키 삭제"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] RDS 제거 여부 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $osVersion = [version]$osInfo.Version
    $spVersion = $osInfo.ServicePackMajorVersion
    
    $isVulnerable = $false
    $statusMsg = ""

    # 판정 기준 1 & 2: 운영체제 버전 확인 (2008 이상이면 양호)
    # Windows Server 2008의 커널 버전은 6.0입니다.
    if ($osVersion.Major -ge 6) {
        $result = "양호"
        $statusMsg = "Windows Server 2008 이상 버전($($osInfo.Caption))을 사용 중이므로 안전합니다."
        $color = "Green"
    } else {
        # 레거시 OS(2003 이하)인 경우 상세 점검 진행
        $isIisInstalled = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
        
        if ($null -eq $isIisInstalled) {
            $result = "양호"
            $statusMsg = "IIS 서비스를 사용하지 않으므로 안전합니다."
            $color = "Green"
        } else {
            # 레지스트리 키 존재 여부 확인
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W3SVC\Parameters\ADCLaunch"
            $vulnerableKeys = @("RDSServer.DataFactory", "AdvancedDataFactory", "VbBusObj.VbBusObjCls")
            $foundKeys = @()

            if (Test-Path $regPath) {
                foreach ($key in $vulnerableKeys) {
                    if (Get-Item -Path "$regPath\$key" -ErrorAction SilentlyContinue) {
                        $foundKeys += $key
                    }
                }
            }

            # MSADC 가상 디렉토리 확인 (WebAdministration 모듈 필요)
            $msadcExists = $false
            if (Get-Module -ListAvailable WebAdministration) {
                Import-Module WebAdministration
                if (Get-WebVirtualDirectory -Site "Default Web Site" -Name "msadc" -ErrorAction SilentlyContinue) {
                    $msadcExists = $true
                }
            }

            if ($foundKeys.Count -gt 0 -or $msadcExists) {
                $result = "취약"
                $statusMsg = "취약한 RDS 설정이 발견되었습니다. (MSADC 존재: $msadcExists, 발견된 키: $($foundKeys -join ', '))"
                $color = "Red"
            } else {
                $result = "양호"
                $statusMsg = "레거시 OS이나 RDS 관련 취약한 설정이 제거되어 있습니다."
                $color = "Green"
            }
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