# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Unnecessary_Services_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-18"
$riskLevel = "상"
$diagnosisItem = "불필요한 서비스 제거"
$remedialAction = "불필요한 서비스를 중지하고 시작 유형을 '사용 안 함'으로 설정 (services.msc)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 불필요한 서비스 제거 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 점검 대상 불필요 서비스 리스트 (주요 취약 서비스)
$targetServices = @(
    @{ Name = "Alerter"; Desc = "알림 서비스" },
    @{ Name = "Messenger"; Desc = "메신저 서비스" },
    @{ Name = "ClipSrv"; Desc = "클립북 서비스" },
    @{ Name = "SimpTcp"; Desc = "Simple TCP/IP Services" },
    @{ Name = "TlntSvr"; Desc = "Telnet" },
    @{ Name = "RemoteRegistry"; Desc = "원격 레지스트리" },
    @{ Name = "Spooler"; Desc = "프린트 스풀러 (서버 용도에 따라 확인 필요)" },
    @{ Name = "Simple TCP/IP Services"; Desc = "단순 TCP/IP 서비스" },
    @{ Name = "freetftp"; Desc = "TFTP 서비스" }
)

# 4. 실제 점검 로직
try {
    $runningUnnecessaryServices = @()
    
    foreach ($service in $targetServices) {
        $svcName = $service.Name
        $svcDesc = $service.Desc
        
        # 서비스 존재 여부 및 상태 확인
        $svcStatus = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        
        if ($null -ne $svcStatus) {
            # 서비스가 존재하고 실행 중이거나, 시작 유형이 '사용 안 함'이 아닌 경우 점검
            $startType = (Get-CimInstance Win32_Service -Filter "Name='$svcName'").StartMode
            
            if ($svcStatus.Status -eq "Running" -or $startType -ne "Disabled") {
                $runningUnnecessaryServices += "$svcDesc($svcName): 상태($($svcStatus.Status))/시작유형($startType)"
            }
        }
    }

    # 5. 판정 로직
    if ($runningUnnecessaryServices.Count -gt 0) {
        $result = "취약"
        $status = "다음의 불필요한 서비스가 구동 중이거나 활성화되어 있습니다: " + ($runningUnnecessaryServices -join ", ")
        $color = "Red"
    } else {
        $result = "양호"
        $status = "모든 주요 불필요 서비스가 중지 및 비활성화되어 있습니다."
        $color = "Green"
    }

} catch {
    $result = "오류"
    $status = "서비스 정보를 가져오는 중 에러 발생: $($_.Exception.Message)"
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