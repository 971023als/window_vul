# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "OS_Build_Version_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-27"
$riskLevel = "상"
$diagnosisItem = "최신 Windows OS Build 버전 적용"
$remedialAction = "Windows 업데이트를 통해 최신 보안 패치 및 빌드 적용 (자동 업데이트 권장)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 최신 OS 빌드 적용 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 3-1. OS 정보 및 빌드 번호 가져오기
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $osName = $os.Caption
    $buildNumber = $os.BuildNumber
    $version = $os.Version

    # 3-2. 마지막 업데이트 설치 날짜 확인 (Get-HotFix 활용)
    # 가장 최근에 설치된 보안 업데이트(KB) 1개를 가져옴
    $lastPatch = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1
    
    $isVulnerable = $false
    $statusMsg = ""

    if ($null -eq $lastPatch) {
        $isVulnerable = $true
        $statusMsg = "설치된 보안 업데이트 기록을 찾을 수 없습니다."
    } else {
        $lastPatchDate = $lastPatch.InstalledOn
        $daysSinceLastPatch = ((Get-Date) - $lastPatchDate).Days
        
        # 판정 기준: 마지막 업데이트 이후 90일이 지났으면 취약으로 간주 (조직 정책에 따라 조정 가능)
        if ($daysSinceLastPatch -gt 90) {
            $isVulnerable = $true
            $statusMsg = "마지막 보안 업데이트 이후 $daysSinceLastPatch일이 경과되었습니다. (최근 패치: $($lastPatch.HotFixID) / $lastPatchDate)"
        } else {
            $statusMsg = "현재 빌드: $buildNumber (최근 패치 날짜: $lastPatchDate, $($daysSinceLastPatch)일 경과)"
        }
    }

    # 3-3. Windows Update 서비스 상태 확인
    $wuaService = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
    if ($wuaService.StartType -eq "Disabled") {
        $isVulnerable = $true
        $statusMsg += " [경고: Windows Update 서비스가 비활성화 상태임]"
    }

    # 4. 최종 결과 판정
    if ($isVulnerable) {
        $result = "취약"
        $color = "Red"
    } else {
        $result = "양호"
        $statusMsg = "시스템이 비교적 최신 상태를 유지하고 있습니다. ($statusMsg)"
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
    "Current Status" = "OS: $osName / $statusMsg"
    "Remedial Action"= $remedialAction
}

# 6. 콘솔 출력 및 CSV 저장
Write-Host "[결과] : $result" -ForegroundColor $color
Write-Host "[현황] : OS: $osName / $statusMsg"
Write-Host "------------------------------------------------"

$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray