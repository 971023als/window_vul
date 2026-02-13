# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Log_File_Access_Control_Check.csv"

# 2. 진단 정보 기본 설정
$category = "로그 관리"
$code = "W-43"
$riskLevel = "중"
$diagnosisItem = "이벤트 로그 파일 접근 통제 설정"
$remedialAction = "로그 디렉터리(config, winevt\Logs, LogFiles)의 NTFS 권한에서 'Everyone' 제거"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 로그 파일 접근 통제 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 점검 대상 디렉터리 설정
    $systemRoot = $env:SystemRoot
    $targetPaths = @(
        "$systemRoot\System32\config",           # 시스템 로그(레거시/구성)
        "$systemRoot\System32\winevt\Logs",      # 현대 Windows 이벤트 로그 실제 경로
        "$systemRoot\System32\LogFiles"          # IIS 및 기타 서비스 로그
    )

    $vulnerablePaths = @()
    $checkedPaths = @()

    foreach ($path in $targetPaths) {
        if (Test-Path $path) {
            $checkedPaths += $path
            $acl = Get-Acl -Path $path
            
            # Everyone (SID: S-1-1-0) 권한 확인
            # 언어 독립적인 점검을 위해 SID와 이름을 모두 체크
            $everyoneAccess = $acl.Access | Where-Object { 
                $_.IdentityReference.Value -eq "Everyone" -or 
                $_.IdentityReference.Value -eq "S-1-1-0" -or
                $_.IdentityReference.Value -match "모든 사용자"
            }

            if ($everyoneAccess) {
                $vulnerablePaths += $path
            }
        }
    }

    # 4. 최종 결과 판정
    if ($vulnerablePaths.Count -gt 0) {
        $result = "취약"
        $statusMsg = "다음 로그 디렉터리에 'Everyone' 권한이 설정되어 있습니다: " + ($vulnerablePaths -join ", ")
        $color = "Red"
    } else {
        $result = "양호"
        $statusMsg = "모든 주요 로그 디렉터리에서 'Everyone' 접근 권한이 적절히 제한되어 있습니다."
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