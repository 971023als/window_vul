# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Password_Policy_Check.csv"

# 2. 진단 정보 기본 설정
$category = "계정관리"
$code = "W-09"
$riskLevel = "상"
$diagnosisItem = "비밀번호 관리 정책 설정"
$remedialAction = "암호 복잡성(사용), 최소길이(8자), 최근암호기억(4회), 최대기간(90일), 최소기간(1일) 설정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 비밀번호 관리 정책 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직 (보안 정책 분석)
try {
    # 보안 정책을 임시 파일로 내보냄
    $tempFile = [System.IO.Path]::GetTempFileName()
    secedit /export /cfg $tempFile /areas SECURITYPOLICY | Out-Null
    $policyContent = Get-Content $tempFile -Encoding Unicode

    # 각 정책 값 추출 함수
    function Get-PolicyValue($key) {
        $line = $policyContent | Select-String $key
        if ($line) { return [int]($line.ToString().Split("=")[1].Trim()) }
        return -1
    }

    $complexity = Get-PolicyValue "PasswordComplexity"      # 1(사용), 0(미사용)
    $history    = Get-PolicyValue "PasswordHistorySize"      # 기억 개수
    $maxAge     = Get-PolicyValue "MaximumPasswordAge"       # 최대 사용 기간
    $minLen     = Get-PolicyValue "MinimumPasswordLength"    # 최소 길이
    $minAge     = Get-PolicyValue "MinimumPasswordAge"       # 최소 사용 기간

    # 4. 판정 로직 (모든 기준 충족 시 양호)
    $isVulnerable = $false
    $details = @()

    if ($complexity -ne 1) { $isVulnerable = $true; $details += "복잡성 미설정" }
    if ($minLen -lt 8)      { $isVulnerable = $true; $details += "최소 길이 8자 미만($minLen)" }
    if ($history -lt 4)     { $isVulnerable = $true; $details += "최근 암호 기억 4개 미만($history)" }
    if ($maxAge -gt 90 -or $maxAge -eq -1) { $isVulnerable = $true; $details += "최대 암호 기간 90일 초과($maxAge)" }
    if ($minAge -lt 1)      { $isVulnerable = $true; $details += "최소 암호 기간 1일 미만($minAge)" }

    if ($isVulnerable) {
        $result = "취약"
        $status = "비밀번호 정책 중 일부가 기준에 미달합니다: " + ($details -join ", ")
        $color = "Red"
    } else {
        $result = "양호"
        $status = "모든 비밀번호 정책(복잡성, 길이, 기억, 기간)이 보안 기준을 만족합니다."
        $color = "Green"
    }

    # 임시 파일 삭제
    if (Test-Path $tempFile) { Remove-Item $tempFile }
} catch {
    $result = "오류"
    $status = "보안 정책 분석 중 오류 발생: $($_.Exception.Message)"
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