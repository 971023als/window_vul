# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Remote_Registry_Service_Check.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-44"
$riskLevel = "상"
$diagnosisItem = "원격 레지스트리 서비스 가동 점검"
$remedialAction = "Remote Registry 서비스를 중지하고 시작 유형을 '사용 안 함'으로 설정 (services.msc)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 원격 레지스트리 서비스 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 3-1. Remote Registry 서비스 정보 가져오기
    $svcName = "RemoteRegistry"
    $remoteRegSvc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    
    if ($null -eq $remoteRegSvc) {
        # 서비스 자체가 없는 경우 (드문 경우지만 안전함)
        $result = "양호"
        $statusMsg = "시스템에 Remote Registry 서비스가 존재하지 않습니다."
        $color = "Green"
    } else {
        # 시작 유형 확인 (Get-CimInstance 사용)
        $startType = (Get-CimInstance Win32_Service -Filter "Name='$svcName'").StartMode
        $currentStatus = $remoteRegSvc.Status

        # 3-2. 판정 로직
        # 서비스가 실행 중(Running)이거나 시작 유형이 'Disabled'가 아닌 경우 취약으로 간주
        if ($currentStatus -eq "Running" -or $startType -ne "Disabled") {
            $result = "취약"
            $statusMsg = "Remote Registry 서비스가 활성화되어 있습니다. (상태: $currentStatus / 시작유형: $startType)"
            $color = "Red"
        } else {
            $result = "양호"
            $statusMsg = "Remote Registry 서비스가 중지 및 비활성화(Disabled) 상태입니다."
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