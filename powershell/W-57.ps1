# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Login_Banner_Check.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-57"
$riskLevel = "하"
$diagnosisItem = "로그온 시 경고 메시지 설정"
$remedialAction = "보안 옵션에서 '로그온 시도하는 사용자에 대한 메시지 제목/텍스트'를 설정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 로그온 경고 메시지 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 레지스트리 경로: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
    # 값 이름: legalnoticecaption (제목), legalnoticetext (내용)
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    
    $isVulnerable = $false
    $statusMsg = ""

    if (Test-Path $regPath) {
        $regValues = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
        $caption = $regValues.legalnoticecaption
        $text = $regValues.legalnoticetext

        # 4. 판정 로직
        # 제목과 내용이 모두 존재하고 비어있지 않아야 양호
        if ([string]::IsNullOrWhiteSpace($caption) -or [string]::IsNullOrWhiteSpace($text)) {
            $isVulnerable = $true
            
            if ([string]::IsNullOrWhiteSpace($caption) -and [string]::IsNullOrWhiteSpace($text)) {
                $statusMsg = "로그온 경고 메시지의 제목과 내용이 모두 설정되어 있지 않습니다."
            } elseif ([string]::IsNullOrWhiteSpace($caption)) {
                $statusMsg = "로그온 경고 메시지의 제목(Caption)이 설정되어 있지 않습니다."
            } else {
                $statusMsg = "로그온 경고 메시지의 내용(Text)이 설정되어 있지 않습니다."
            }
        } else {
            $result = "양호"
            $statusMsg = "로그온 경고 메시지가 적절히 설정되어 있습니다. (제목: $caption)"
            $color = "Green"
        }

        if ($isVulnerable) {
            $result = "취약"
            $color = "Red"
        }
    } else {
        $result = "오류"
        $statusMsg = "정책 레지스트리 경로를 찾을 수 없습니다."
        $color = "Yellow"
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