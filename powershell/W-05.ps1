# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Reversible_Encryption_Check.csv"

# 2. 진단 정보 기본 설정
$category = "계정관리"
$code = "W-05"
$riskLevel = "상"
$diagnosisItem = "해독 가능한 암호화를 사용하여 암호 저장 해제"
$remedialAction = "'해독 가능한 암호화를 사용하여 암호 저장' 정책을 '사용 안 함'으로 설정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 해독 가능한 암호화 저장 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직 (보안 정책 분석)
try {
    # 보안 정책을 임시 파일로 내보냄
    $tempFile = [System.IO.Path]::GetTempFileName()
    secedit /export /cfg $tempFile /areas SECURITYPOLICY | Out-Null
    
    # 내보낸 파일에서 ClearTextPassword(해독 가능한 암호화 사용 여부) 검색
    $policyContent = Get-Content $tempFile -Encoding Unicode
    $clearTextLine = $policyContent | Select-String "ClearTextPassword"
    
    if ($clearTextLine) {
        # 값 추출 (0: 사용 안 함, 1: 사용)
        $clearTextVal = [int]($clearTextLine.ToString().Split("=")[1].Trim())
        
        if ($clearTextVal -eq 1) {
            $result = "취약"
            $status = "비밀번호를 해독 가능한 암호화 방식으로 저장하도록 설정되어 있습니다(Enabled)."
            $color = "Red"
        } else {
            $result = "양호"
            $status = "비밀번호를 해독 가능한 암호화 방식으로 저장하지 않도록 설정되어 있습니다(Disabled)."
            $color = "Green"
        }
    } else {
        # 해당 라인이 없는 경우 기본적으로 윈도우는 '사용 안 함'이므로 양호로 판단하나 확인 필요
        $result = "양호"
        $status = "관련 정책 설정이 발견되지 않았습니다(기본값: Disabled)."
        $color = "Green"
    }

    # 임시 파일 삭제
    if (Test-Path $tempFile) { Remove-Item $tempFile }
} catch {
    $result = "오류"
    $status = "보안 정책 분석 중 오류 발생: $($_.Exception.Message)"
    $color = "Yellow"
}

# 4. 결과 객체 생성
$report = [PSCustomObject]@{
    "Category"       = $category
    "Code"           = $code
    "Risk Level"     = $riskLevel
    "Diagnosis Item" = $diagnosisItem
    "Result"         = $result
    "Current Status" = $status
    "Remedial Action"= $remedialAction
}

# 5. 콘솔 출력 및 CSV 저장
Write-Host "[결과] : $result" -ForegroundColor $color
Write-Host "[현황] : $status"
Write-Host "------------------------------------------------"

# CSV 저장 (Append 모드)
$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray