# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Remote_Desktop_Users_Check.csv"

# 2. 진단 정보 기본 설정
$category = "계정관리"
$code = "W-14"
$riskLevel = "중"
$diagnosisItem = "원격터미널 접속 가능한 사용자 그룹 제한"
$remedialAction = "Remote Desktop Users 그룹에서 불필요한 계정 제거 및 전용 계정 운영 (lusrmgr.msc)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 원격터미널 그룹 제한 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직 (Remote Desktop Users 그룹 구성원 확인)
try {
    # 원격 데스크톱 사용자 그룹(SID S-1-5-32-555) 찾기 (한글/영문 호환)
    $rdpGroup = Get-CimInstance -ClassName Win32_Group | Where-Object { $_.SID -eq "S-1-5-32-555" }
    
    if ($null -eq $rdpGroup) {
        $result = "양호"
        $status = "Remote Desktop Users 그룹이 존재하지 않거나 구성원이 없습니다."
        $color = "Green"
    } else {
        # 그룹 구성원 가져오기
        $members = Get-CimInstance -ClassName Win32_GroupUser | Where-Object { $_.GroupComponent -match $rdpGroup.Name }
        
        $memberList = @()
        foreach ($member in $members) {
            if ($member.PartComponent -match 'Name="([^"]+)"') {
                $memberList += $matches[1]
            }
        }

        # 4. 판정 로직
        if ($memberList.Count -eq 0) {
            $result = "양호"
            $status = "원격 접속 그룹에 등록된 계정이 없습니다. (기본적으로 Administrators만 허용됨)"
            $color = "Green"
        } else {
            # 불필요한 계정(Everyone, Guest, Users 그룹 등)이 포함되어 있는지 확인
            $vulnerableEntries = $memberList | Where-Object { $_ -match "Everyone|Users|Guest" }
            
            if ($vulnerableEntries) {
                $result = "취약"
                $status = "원격 접속 그룹에 불필요하거나 과도한 권한의 그룹/계정이 포함되어 있습니다: " + ($vulnerableEntries -join ", ")
                $color = "Red"
            } else {
                $result = "양호"
                $status = "원격 접속 그룹이 적절하게 제한되어 있습니다. 구성원: " + ($memberList -join ", ")
                $color = "Green"
            }
        }
    }
} catch {
    $result = "오류"
    $status = "원격 그룹 정보를 가져오는 중 에러 발생: $($_.Exception.Message)"
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