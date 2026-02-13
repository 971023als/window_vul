# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Share_Permissions_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-16"
$riskLevel = "상"
$diagnosisItem = "공유 권한 및 사용자 그룹 설정"
$remedialAction = "일반 공유 폴더에서 'Everyone' 권한을 제거하고 실제 필요한 계정만 추가 (fsmgmt.msc)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 공유 권한 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 윈도우 공유 정보 가져오기 (관리 공유 제외)
    $shares = Get-SmbShare | Where-Object { $_.Special -eq $false -and $_.Name -notlike "*$" }
    
    $vulnerableShares = @()
    $totalShares = 0

    if ($null -eq $shares) {
        $result = "양호"
        $status = "시스템에 생성된 일반 공유 디렉터리가 없습니다."
        $color = "Green"
    } else {
        foreach ($share in $shares) {
            $totalShares++
            # 공유 권한(Access Control List) 가져오기
            $accessList = Get-SmbShareAccess -Name $share.Name
            
            # Everyone 그룹 (SID: S-1-1-0) 포함 여부 확인
            $everyoneAccess = $accessList | Where-Object { $_.AccountName -eq "Everyone" -or $_.AccountName -eq "모든 사용자" }
            
            if ($everyoneAccess) {
                $vulnerableShares += "$($share.Name)($($share.Path))"
            }
        }

        # 4. 판정 로직
        if ($vulnerableShares.Count -gt 0) {
            $result = "취약"
            $status = "다음 공유 폴더에 'Everyone' 권한이 설정되어 있습니다: " + ($vulnerableShares -join ", ")
            $color = "Red"
        } else {
            $result = "양호"
            $status = "총 $($totalShares)개의 일반 공유 폴더가 적절한 권한으로 관리되고 있습니다."
            $color = "Green"
        }
    }
} catch {
    $result = "오류"
    $status = "공유 정보를 가져오는 중 에러 발생: $($_.Exception.Message)"
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