# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Anonymous_Access_Restriction_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-23"
$riskLevel = "상"
$diagnosisItem = "공유 서비스에 대한 익명 접근 제한 설정"
$remedialAction = "FTP 익명 인증 비활성화 및 레지스트리 RestrictAnonymous 설정(1 이상) 적용"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] 익명 접근 제한 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    $vulnerabilities = @()
    $isFtpInstalled = $false

    # --- [Step 1] IIS FTP 익명 인증 점검 ---
    if (Get-Module -ListAvailable WebAdministration) {
        Import-Module WebAdministration
        $ftpSites = Get-ChildItem -Path "IIS:\Sites" | Where-Object { $_.bindings.protocol -contains "ftp" }
        
        if ($ftpSites) {
            $isFtpInstalled = $true
            foreach ($site in $ftpSites) {
                # 익명 인증(anonymousAuthentication) 활성화 여부 확인
                $anonAuth = Get-WebConfigurationProperty -Filter "/system.ftpServer/security/authentication/anonymousAuthentication" -Name "enabled" -PSPath "IIS:\Sites\$($site.Name)"
                
                if ($anonAuth.Value -eq $true) {
                    $vulnerabilities += "FTP 사이트 '$($site.Name)': 익명 인증 활성화됨"
                }
            }
        }
    }

    # --- [Step 2] 시스템 익명 연결 제한 레지스트리 점검 (SMB 등 영향) ---
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    $regName = "RestrictAnonymous"
    $restrictAnon = (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue).$regName

    # RestrictAnonymous 값이 0이면 익명 접근 허용 (취약)
    # 1: 익명 열거 제한, 2: 익명 접근 완전 제한
    if ($null -eq $restrictAnon -or $restrictAnon -eq 0) {
        $vulnerabilities += "시스템 정책: RestrictAnonymous 값이 0(허용)으로 설정됨"
    }

    # 4. 최종 판정 로직
    if ($vulnerabilities.Count -gt 0) {
        $result = "취약"
        $status = "익명 접근이 허용된 항목이 발견되었습니다: " + ($vulnerabilities -join " / ")
        $color = "Red"
    } else {
        $result = "양호"
        $status = "모든 공유 서비스 및 시스템 정책에서 익명 접근이 적절히 제한되고 있습니다."
        $color = "Green"
    }

} catch {
    $result = "오류"
    $status = "점검 중 에러 발생: $($_.Exception.Message)"
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

$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray