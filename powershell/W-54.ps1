# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "DoS_Defense_Registry_Check.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-54"
$riskLevel = "중"
$diagnosisItem = "DoS 공격 방어 레지스트리 설정"
$remedialAction = "Tcpip\Parameters 경로에 SynAttackProtect 등 4개 항목 권고치 적용"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] DoS 방어 레지스트리 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 레지스트리 경로: HKLM\System\CurrentControlSet\Services\Tcpip\Parameters
    $regPath = "HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters"
    
    # 점검 기준 정의
    $checkList = @(
        @{ Name = "SynAttackProtect"; Expected = 1; Compare = "ge" }, # 1 이상
        @{ Name = "EnableDeadGWDetect"; Expected = 0; Compare = "eq" }, # 0
        @{ Name = "KeepAliveTime"; Expected = 300000; Compare = "eq" }, # 300,000
        @{ Name = "NoNameReleaseOnDemand"; Expected = 1; Compare = "eq" } # 1
    )

    $vulnerableItems = @()
    $currentSettings = @()

    if (Test-Path $regPath) {
        $regValues = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue

        foreach ($item in $checkList) {
            $valName = $item.Name
            $currentVal = $regValues.$valName

            if ($null -eq $currentVal) {
                $vulnerableItems += "$valName (값 없음)"
                $currentSettings += "$valName=Missing"
            } else {
                $currentSettings += "$valName=$currentVal"
                
                # 비교 로직
                $isPass = $false
                if ($item.Compare -eq "ge") {
                    if ($currentVal -ge $item.Expected) { $isPass = $true }
                } elseif ($item.Compare -eq "eq") {
                    if ($currentVal -eq $item.Expected) { $isPass = $true }
                }

                if (-not $isPass) {
                    $vulnerableItems += "$valName (현재:$currentVal / 권고:$($item.Expected))"
                }
            }
        }
    } else {
        $result = "오류"
        $statusMsg = "Tcpip\Parameters 레지스트리 경로를 찾을 수 없습니다."
    }

    # 4. 최종 결과 판정
    if ($vulnerableItems.Count -gt 0) {
        $result = "취약"
        $statusMsg = "다음 항목이 권고치와 다릅니다: " + ($vulnerableItems -join ", ")
        $color = "Red"
    } else {
        $result = "양호"
        $statusMsg = "모든 DoS 방어 레지스트리가 적절히 설정되어 있습니다."
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
    "Current Status" = $statusMsg
    "Remedial Action"= $remedialAction
}

# 6. 콘솔 출력 및 CSV 저장
Write-Host "[결과] : $result" -ForegroundColor $color
Write-Host "[현황] : $statusMsg"
Write-Host "------------------------------------------------"

$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray