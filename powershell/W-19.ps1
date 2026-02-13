# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "IIS_Service_Running_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-19"
$riskLevel = "상"
$diagnosisItem = "불필요한 IIS 서비스 구동 점검"
$remedialAction = "웹 서비스 미사용 시 IIS 관련 서비스를 중지하고 '사용 안 함'으로 설정 (services.msc)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] IIS 서비스 구동 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 점검 대상 IIS 관련 서비스 리스트
$iisServices = @(
    @{ Name = "W3SVC"; Desc = "World Wide Web Publishing Service" },
    @{ Name = "IISADMIN"; Desc = "IIS Admin Service" },
    @{ Name = "MSFTPSVC"; Desc = "Microsoft FTP Service" }
)

# 4. 실제 점검 로직
try {
    $runningIISServices = @()
    $isInstalled = $false

    foreach ($service in $iisServices) {
        $svcName = $service.Name
        $svcDesc = $service.Desc
        
        # 서비스 정보 가져오기
        $svcStatus = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        
        if ($null -ne $svcStatus) {
            $isInstalled = $true
            # 시작 유형 확인 (Get-CimInstance 사용)
            $startType = (Get-CimInstance Win32_Service -Filter "Name='$svcName'").StartMode
            
            # 서비스가 실행 중이거나 시작 유형이 비활성화가 아닌 경우
            if ($svcStatus.Status -eq "Running" -or $startType -ne "Disabled") {
                $runningIISServices += "$svcDesc($svcName): 상태($($svcStatus.Status))/시작유형($startType)"
            }
        }
    }

    # 5. 판정 로직
    if (-not $isInstalled) {
        $result = "양호"
        $status = "시스템에 IIS 서비스가 설치되어 있지 않습니다."
        $color = "Green"
    } elseif ($runningIISServices.Count -gt 0) {
        # IIS가 설치되어 있고 실행 중인 경우 -> 업무상 필요 여부를 관리자가 판단해야 함
        $result = "취약"
        $status = "IIS 서비스가 구동 중이거나 활성화되어 있습니다(업무상 필요 여부 검토 필요): " + ($runningIISServices -join ", ")
        $color = "Red"
    } else {
        $result = "양호"
        $status = "IIS 서비스가 설치되어 있으나 모두 중지 및 비활성화 상태입니다."
        $color = "Green"
    }

} catch {
    $result = "오류"
    $status = "IIS 서비스 정보를 가져오는 중 에러 발생: $($_.Exception.Message)"
    $color = "Yellow"
}

# 6. 결과 객체 생성
$report = [PSCustomObject]@{
    "Category"       = $category
    "Code"           = $code
    "Risk Level"     = $riskLevel
    "Diagnosis Item" = $diagnosisItem
    "Result"         = $result
    "Current Status" = $status
    "Remedial Action"= $remedialAction
}

# 7. 콘솔 출력 및 CSV 저장
Write-Host "[결과] : $result" -ForegroundColor $color
Write-Host "[현황] : $status"
Write-Host "------------------------------------------------"

# CSV 저장 (Append 모드)
$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray