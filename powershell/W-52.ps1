# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Autologon_Function_Check.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-52"
$riskLevel = "상"
$diagnosisItem = "Autologon 기능 제어"
$remedialAction = "AutoAdminLogon 값을 '0'으로 설정하고, 레지스트리의 DefaultPassword 값 제거"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] Autologon 기능 제어 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 레지스트리 경로: HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    
    $isVulnerable = $false
    $statusMsg = ""

    if (Test-Path $regPath) {
        $regValues = Get-ItemProperty -Path $regPath
        $autoLogon = $regValues.AutoAdminLogon
        $defaultPassword = $regValues.DefaultPassword

        # 4. 판정 로직
        # 4-1. AutoAdminLogon 확인
        if ($null -eq $autoLogon -or $autoLogon -eq "0") {
            # 기본적으로 양호하나 DefaultPassword가 남아있는지 추가 확인
            if ($null -ne $defaultPassword) {
                $isVulnerable = $true
                $statusMsg = "자동 로그인은 비활성화되어 있으나, 레지스트리에 평문 비밀번호(DefaultPassword)가 존재합니다."
            } else {
                $result = "양호"
                $statusMsg = "자동 로그인 기능이 비활성화되어 있습니다."
                $color = "Green"
            }
        } elseif ($autoLogon -eq "1") {
            $isVulnerable = $true
            $statusMsg = "자동 로그인(AutoAdminLogon) 기능이 활성화되어 있습니다."
        }

        # 취약 최종 확인
        if ($isVulnerable) {
            $result = "취약"
            $color = "Red"
        }
    } else {
        $result = "오류"
        $statusMsg = "Winlogon 레지스트리 경로를 찾을 수 없습니다."
        $color = "Yellow"
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