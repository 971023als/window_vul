# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Admin_Group_Member_Check.csv"

# 2. 진단 정보 기본 설정
$category = "계정관리"
$code = "W-06"
$riskLevel = "상"
$diagnosisItem = "관리자 그룹에 최소한의 사용자 포함"
$remedialAction = "Administrators 그룹에서 불필요한 계정 제거 (lusrmgr.msc)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 관리자 그룹 최소 사용자 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직 (로컬 관리자 그룹 구성원 확인)
try {
    # 로컬 관리자 그룹(SID S-1-5-32-544) 찾기 (한글/영문 윈도우 호환)
    $adminGroup = Get-CimInstance -ClassName Win32_Group | Where-Object { $_.SID -eq "S-1-5-32-544" }
    
    # 그룹 구성원 가져오기
    $query = "GroupComponent='Win32_Group.Domain=""$($adminGroup.Domain)"",Name=""$($adminGroup.Name)""'"
    $members = Get-CimInstance -ClassName Win32_GroupUser | Where-Object { $_.GroupComponent -match $adminGroup.Name }
    
    $memberList = @()
    $adminCount = 0

    foreach ($member in $members) {
        # 'Name="계정명"' 부분에서 이름 추출
        if ($member.PartComponent -match 'Name="([^"]+)"') {
            $name = $matches[1]
            
            # 기본 빌트인 Administrator 계정(SID 끝자리 500) 확인
            $userObj = Get-CimInstance -ClassName Win32_UserAccount | Where-Object { $_.Name -eq $name }
            
            if ($userObj.SID -like "*-500") {
                $memberList += "$name (빌트인 관리자)"
            } else {
                $memberList += "$name (추가된 관리자)"
                $adminCount++
            }
        }
    }

    # 4. 판정 로직
    # 빌트인 계정 외에 추가된 계정이 있으면 취약으로 간주 (정책에 따라 1명 초과 시 취약)
    if ($adminCount -gt 0) {
        $result = "취약"
        $status = "관리자 그룹에 불필요한 계정(기본 계정 외 $($adminCount)명)이 포함되어 있습니다: " + ($memberList -join ", ")
        $color = "Red"
    } else {
        $result = "양호"
        $status = "관리자 그룹 구성원이 적절하게 관리되고 있습니다 (구성원: " + ($memberList -join ", ") + ")"
        $color = "Green"
    }

} catch {
    $result = "오류"
    $status = "관리자 그룹 정보를 가져오는 중 에러 발생: $($_.Exception.Message)"
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

# CSV 저장 (UTF8 적용)
$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray