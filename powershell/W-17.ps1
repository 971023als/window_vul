# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Default_Share_Removal_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-17"
$riskLevel = "상"
$diagnosisItem = "하드디스크 기본 공유 제거"
$remedialAction = "레지스트리 AutoShareServer 값을 0으로 설정하고 기본 공유 중지 (관리 공유 제거)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 하드디스크 기본 공유 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 3-1. 레지스트리 값 확인 (AutoShareServer)
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
    $regName = "AutoShareServer"
    $autoShareValue = (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue).$regName

    # 3-2. 현재 활성화된 기본 공유 드라이브 확인 (C$, D$, ADMIN$ 등)
    # IPC$는 관리상 제외하는 것이 일반적이므로 필터링에서 제외
    $activeDefaultShares = Get-SmbShare | Where-Object { $_.Name -match '^[A-Z]\$$|^ADMIN\$' }

    # 4. 판정 로직
    # 레지스트리 값이 0이고, 실제 드라이브 공유가 없어야 양호
    if (($null -ne $autoShareValue -and $autoShareValue -eq 0) -and ($null -eq $activeDefaultShares)) {
        $result = "양호"
        $status = "기본 공유가 비활성화되어 있으며(AutoShareServer=0), 활성화된 관리 공유 드라이브가 없습니다."
        $color = "Green"
    } else {
        $result = "취약"
        $shareNames = if ($activeDefaultShares) { ($activeDefaultShares.Name -join ", ") } else { "없음" }
        $regStatus = if ($null -eq $autoShareValue) { "설정 안 됨(기본값 1)" } else { $autoShareValue }
        
        $status = "기본 공유가 활성화되어 있습니다. (레지스트리: $regStatus, 활성 공유: $shareNames)"
        $color = "Red"
    }
} catch {
    $result = "오류"
    $status = "점검 중 에러 발생: $($_.Exception.Message)"
    $color = "Yellow"
}

# 5. 결과 객체 생성
$report = [PSCustomObject]@{
    "Category"       = $category
    "Code"           = $code
    "Risk Level"     = $riskLevel
    "Diagnosis Item" = $diagnosisItem
    "Result"         = $result
    "Current Status" = $status
    "Remedial Action"= $remedialAction
}

# 6. 콘솔 출력 및 CSV 저장
Write-Host "[결과] : $result" -ForegroundColor $color
Write-Host "[현황] : $status"
Write-Host "------------------------------------------------"

# CSV 저장 (Append 모드)
$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray