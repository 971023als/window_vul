# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "File_System_Security_Check.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-61"
$riskLevel = "중"
$diagnosisItem = "NTFS 파일 시스템 사용 여부 점검"
$remedialAction = "FAT 계열 파일 시스템을 NTFS로 변환 (명령어: convert 드라이브: /fs:ntfs)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 파일 시스템 보안 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 3-1. 모든 로컬 디스크(DriveType 3) 정보 가져오기
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
    
    $vulnerableDisks = @()
    $diskDetails = @()
    $isVulnerable = $false

    foreach ($disk in $disks) {
        $drive = $disk.DeviceID
        $fsType = $disk.FileSystem
        $diskDetails += "$drive ($fsType)"

        # NTFS 또는 ReFS(차세대 보안 파일시스템)가 아닌 경우 취약으로 간주
        if ($fsType -notmatch "NTFS|ReFS") {
            $isVulnerable = $true
            $vulnerableDisks += "$drive ($fsType)"
        }
    }

    # 4. 판정 로직
    if ($isVulnerable) {
        $result = "취약"
        $statusMsg = "보안 기능이 없는 파일 시스템이 발견되었습니다: " + ($vulnerableDisks -join ", ")
        $color = "Red"
    } else {
        $result = "양호"
        $statusMsg = "모든 로컬 드라이브가 보안 파일 시스템(NTFS/ReFS)을 사용 중입니다. (" + ($diskDetails -join ", ") + ")"
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