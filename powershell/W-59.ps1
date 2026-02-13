# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "LAN_Manager_Auth_Level_Check.csv"

# 2. 진단 정보 기본 설정
$category = "보안 관리"
$code = "W-59"
$riskLevel = "중"
$diagnosisItem = "LAN Manager 인증 수준 설정"
$remedialAction = "보안 옵션에서 '네트워크 보안: LAN Manager 인증 수준'을 'NTLMv2 응답만 보내기'로 설정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] LAN Manager 인증 수준 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 레지스트리 경로: HKLM\SYSTEM\CurrentControlSet\Control\Lsa
    # 값 이름: LmCompatibilityLevel
    # 0~2: LM/NTLM 포함 (취약)
    # 3: NTLMv2 응답만 보냄 (양호)
    # 4: NTLMv2 응답만 보냄. LM 거부 (양호)
    # 5: NTLMv2 응답만 보냄. LM & NTLM 거부 (양호)
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    $valueName = "LmCompatibilityLevel"
    
    $isVulnerable = $false
    $statusMsg = ""

    if (Test-Path $regPath) {
        $regValue = (Get-ItemProperty -Path $regPath -Name $valueName -ErrorAction SilentlyContinue).$valueName
        
        # 4. 판정 로직
        if ($null -eq $regValue) {
            # 값이 명시되어 있지 않은 경우 (현대 Windows Server 기본값은 보통 3 이상이지만 보안 감사는 명시적 설정을 권고함)
            $isVulnerable = $true
            $statusMsg = "LAN Manager 인증 수준 값이 레지스트리에 명시되어 있지 않습니다."
        } else {
            switch ($regValue) {
                0 { $msg = "LM 및 NTLM 응답 보내기 (0)"; $isVulnerable = $true }
                1 { $msg = "협상된 경우 NTLMv2 세션 보안 사용 (1)"; $isVulnerable = $true }
                2 { $msg = "NTLM 응답만 보내기 (2)"; $isVulnerable = $true }
                3 { $msg = "NTLMv2 응답만 보내기 (3)"; $isVulnerable = $false }
                4 { $msg = "NTLMv2 응답만 보내기. LM 거부 (4)"; $isVulnerable = $false }
                5 { $msg = "NTLMv2 응답만 보내기. LM 및 NTLM 거부 (5)"; $isVulnerable = $false }
                Default { $msg = "알 수 없는 설정값 ($regValue)"; $isVulnerable = $true }
            }
            $statusMsg = "현재 설정: $msg"
        }

        if ($isVulnerable) {
            $result = "취약"
            $color = "Red"
        } else {
            $result = "양호"
            $color = "Green"
        }
    } else {
        $result = "오류"
        $statusMsg = "Lsa 레지스트리 경로를 찾을 수 없습니다."
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