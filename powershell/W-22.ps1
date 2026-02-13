# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "FTP_Directory_Permission_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-22"
$riskLevel = "상"
$diagnosisItem = "FTP 디렉토리 접근권한 설정"
$remedialAction = "FTP 홈 디렉터리에서 'Everyone' 권한을 제거하고 승인된 계정만 추가 (NTFS 권한 설정)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] FTP 디렉터리 권한 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # IIS 관리 모듈 확인
    if (!(Get-Module -ListAvailable WebAdministration)) {
        $result = "양호"
        $status = "IIS 서비스가 설치되어 있지 않아 점검 대상이 아닙니다."
        $color = "Green"
    } else {
        Import-Module WebAdministration
        $ftpSites = Get-ChildItem -Path "IIS:\Sites" | Where-Object { $_.bindings.protocol -contains "ftp" }

        if ($null -eq $ftpSites -or $ftpSites.Count -eq 0) {
            $result = "양호"
            $status = "구성된 FTP 사이트가 없습니다."
            $color = "Green"
        } else {
            $vulnerablePaths = @()
            foreach ($site in $ftpSites) {
                $siteName = $site.name
                $physicalPath = $site.physicalPath
                
                if (Test-Path $physicalPath) {
                    $acl = Get-Acl -Path $physicalPath
                    # Everyone (S-1-1-0) 권한 확인
                    $everyoneAccess = $acl.Access | Where-Object { 
                        $_.IdentityReference.Value -eq "Everyone" -or 
                        $_.IdentityReference.Value -eq "S-1-1-0" -or
                        $_.IdentityReference.Value -match "모든 사용자"
                    }

                    if ($everyoneAccess) {
                        $vulnerablePaths += "사이트: $siteName (경로: $physicalPath)"
                    }
                }
            }

            if ($vulnerablePaths.Count -gt 0) {
                $result = "취약"
                $status = "다음 FTP 홈 디렉터리에 'Everyone' 권한이 설정되어 있습니다: " + ($vulnerablePaths -join ", ")
                $color = "Red"
            } else {
                $result = "양호"
                $status = "모든 FTP 홈 디렉터리의 접근 권한이 적절하게 설정되어 있습니다."
                $color = "Green"
            }
        }
    }
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