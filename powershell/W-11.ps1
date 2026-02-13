# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Local_Logon_Right_Check.csv"

# 2. 진단 정보 기본 설정
$category = "계정관리"
$code = "W-11"
$riskLevel = "중"
$diagnosisItem = "로컬 로그온 허용"
$remedialAction = "Administrators, IUSR_ 외 불필요한 계정 제거 (secpol.msc)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 로컬 로그온 허용 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직 (사용자 권한 할당 분석)
try {
    # 보안 정책 권한 할당 부분 내보내기
    $tempFile = [System.IO.Path]::GetTempFileName()
    secedit /export /cfg $tempFile /areas USER_RIGHTS | Out-Null
    $policyContent = Get-Content $tempFile -Encoding Unicode

    # SeInteractiveLogonRight (로컬로 로그온 허용) 라인 추출
    $logonRightLine = $policyContent | Select-String "SeInteractiveLogonRight"
    
    $isVulnerable = $false
    $currentMembers = @()
    $vulnerableMembers = @()

    if ($logonRightLine) {
        # SID 리스트 추출 (쉼표로 구분됨)
        $sids = $logonRightLine.ToString().Split("=")[1].Split(",")
        
        foreach ($sid in $sids) {
            $sidStr = $sid.Trim().Replace("*", "") # secedit은 SID 앞에 *를 붙임
            try {
                # SID를 계정 이름으로 변환
                $objSid = New-Object System.Security.Principal.SecurityIdentifier($sidStr)
                $accountName = $objSid.Translate([System.Security.Principal.NTAccount]).Value
                $currentMembers += $accountName

                # 판정 로직: Administrators 그룹 또는 IUSR 계정인지 확인
                # (S-1-5-32-544 는 Administrators의 잘 알려진 SID임)
                $isAdmin = ($sidStr -eq "S-1-5-32-544") -or ($accountName -match "Administrators")
                $isIusr = ($accountName -match "IUSR")
                
                if (-not ($isAdmin -or $isIusr)) {
                    $isVulnerable = $true
                    $vulnerableMembers += $accountName
                }
            } catch {
                # 변환 실패 시 (삭제된 계정 등)
                $currentMembers += "Unknown($sidStr)"
                $isVulnerable = $true
                $vulnerableMembers += $sidStr
            }
        }

        if ($isVulnerable) {
            $result = "취약"
            $status = "권장 계정 외에 다음 계정이 로컬 로그온 권한을 가지고 있습니다: " + ($vulnerableMembers -join ", ")
            $color = "Red"
        } else {
            $result = "양호"
            $status = "Administrators 및 IUSR 계정만 로컬 로그온 권한을 가지고 있습니다."
            $color = "Green"
        }
    } else {
        $result = "오류"
        $status = "로컬 로그온 허용 정책 정보를 찾을 수 없습니다."
        $color = "Yellow"
    }

    # 임시 파일 삭제
    if (Test-Path $tempFile) { Remove-Item $tempFile }
} catch {
    $result = "오류"
    $status = "점검 중 에러 발생: $($_.Exception.Message)"
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

$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray