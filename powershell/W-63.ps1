# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Kerberos_Time_Sync_Check.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-63"
$riskLevel = "중"
$diagnosisItem = "도메인 컨트롤러-사용자의 시간 동기화"
$remedialAction = "보안 정책에서 '컴퓨터 시계 동기화 최대 허용 오차'를 5분 이하로 설정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] Kerberos 시계 동기화 오차 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 3-1. 로컬 보안 정책 내보내기 (Kerberos 정책 포함)
    $tempFile = [System.IO.Path]::GetTempFileName()
    secedit /export /cfg $tempFile /areas SECURITYPOLICY | Out-Null
    
    # 내보낸 파일 읽기 (유니코드 인코딩)
    $policyContent = Get-Content $tempFile -Encoding Unicode
    
    # 3-2. 'MaxClockSkew' (최대 허용 오차) 값 추출
    # 기본값은 5분이며, 정책 파일에는 분 단위로 기록됨
    $skewMatch = $policyContent | Where-Object { $_ -match "MaxClockSkew" }
    
    $isVulnerable = $false
    $statusMsg = ""

    if ($null -eq $skewMatch) {
        # 도메인에 가입되지 않은 단독 서버의 경우 해당 정책이 명시되지 않을 수 있음
        $result = "양호"
        $statusMsg = "Kerberos 정책이 명시되어 있지 않습니다. (기본값 5분 사용 중)"
        $color = "Green"
    } else {
        $skewValue = [int]($skewMatch.Split('=')[1].Trim())

        # 4. 판정 로직: 5분 초과 시 취약
        if ($skewValue -gt 5) {
            $isVulnerable = $true
            $statusMsg = "최대 허용 오차가 5분을 초과하여 설정되어 있습니다. (현재: $skewValue 분)"
            $result = "취약"
            $color = "Red"
        } else {
            $result = "양호"
            $statusMsg = "최대 허용 오차가 권고 기준($skewValue 분) 내에 있습니다."
            $color = "Green"
        }
    }
} catch {
    $result = "오류"
    $statusMsg = "점검 중 에러 발생: $($_.Exception.Message)"
    $color = "Yellow"
} finally {
    if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
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