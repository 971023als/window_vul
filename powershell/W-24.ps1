# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "FTP_Access_Control_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-24"
$riskLevel = "상"
$diagnosisItem = "FTP 접근 제어 설정"
$remedialAction = "IIS FTP IP 주소 및 도메인 제한에서 '미지정 클라이언트 액세스'를 '거부'로 설정하고 허용 IP 등록"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] FTP 접근 제어 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # IIS 관리 모듈 확인
    if (!(Get-Module -ListAvailable WebAdministration)) {
        $result = "양호"
        $status = "IIS 서비스가 설치되어 있지 않아 FTP 접근 제어 점검 대상이 아닙니다."
        $color = "Green"
    } else {
        Import-Module WebAdministration
        $ftpSites = Get-ChildItem -Path "IIS:\Sites" | Where-Object { $_.bindings.protocol -contains "ftp" }

        if ($null -eq $ftpSites -or $ftpSites.Count -eq 0) {
            $result = "양호"
            $status = "구성된 FTP 사이트가 없어 접근 제어 점검이 필요하지 않습니다."
            $color = "Green"
        } else {
            $vulnerableSites = @()
            foreach ($site in $ftpSites) {
                $siteName = $site.name
                
                # FTP IP 보안 설정 가져오기 (allowUnlisted 속성 확인)
                # allowUnlisted="true" 이면 모든 IP 허용 (취약)
                # allowUnlisted="false" 이면 특정 IP만 허용 (양호)
                $ipSecurity = Get-WebConfigurationProperty -Filter "/system.ftpServer/security/ipSecurity" -Name "allowUnlisted" -PSPath "IIS:\Sites\$siteName"
                
                if ($ipSecurity.Value -eq $true) {
                    $vulnerableSites += $siteName
                }
            }

            if ($vulnerableSites.Count -gt 0) {
                $result = "취약"
                $status = "다음 FTP 사이트에서 미지정 IP 접근을 허용하고 있습니다: " + ($vulnerableSites -join ", ")
                $color = "Red"
            } else {
                $result = "양호"
                $status = "모든 FTP 사이트에 특정 IP만 허용하는 접근 제어 설정이 적용되어 있습니다."
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