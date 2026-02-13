# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "Telnet_Service_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-34"
$riskLevel = "중"
$diagnosisItem = "Telnet 서비스 비활성화"
$remedialAction = "Telnet 서비스 중지 및 '사용 안 함' 설정 (필요 시 NTLM 인증만 허용)"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] Telnet 서비스 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 3-1. Telnet 서비스(TlntSvr) 존재 및 상태 확인
    $telnetSvc = Get-Service -Name "TlntSvr" -ErrorAction SilentlyContinue
    
    if ($null -eq $telnetSvc -or $telnetSvc.Status -ne "Running") {
        $result = "양호"
        $statusMsg = "Telnet 서비스가 설치되어 있지 않거나 중지 상태입니다."
        $color = "Green"
    } else {
        # 3-2. 서비스가 구동 중인 경우 인증 방식 확인 (Windows 2012 이하)
        # Registry: HKLM\SOFTWARE\Microsoft\TelnetServer\1.0\Security
        $regPath = "HKLM:\SOFTWARE\Microsoft\TelnetServer\1.0\Security"
        
        if (Test-Path $regPath) {
            # NTLM 값 확인 (1: 사용, 0: 미사용)
            $ntlmAuth = (Get-ItemProperty -Path $regPath -Name "NTLM" -ErrorAction SilentlyContinue).NTLM
            
            # Passwd 값 확인 (암호 인증 사용 여부 - 1: 허용, 0: 거부)
            $passwdAuth = (Get-ItemProperty -Path $regPath -Name "Passwd" -ErrorAction SilentlyContinue).Passwd

            if ($ntlmAuth -eq 1 -and ($null -eq $passwdAuth -or $passwdAuth -eq 0)) {
                $result = "양호"
                $statusMsg = "Telnet 서비스가 구동 중이나 NTLM 인증만 사용하도록 안전하게 설정되어 있습니다."
                $color = "Green"
            } else {
                $result = "취약"
                $statusMsg = "Telnet 서비스가 구동 중이며 취약한 암호 인증(Password)이 활성화되어 있습니다."
                $color = "Red"
            }
        } else {
            # 레지스트리 설정이 확인되지 않는 경우 (기본적으로 취약으로 간주)
            $result = "취약"
            $statusMsg = "Telnet 서비스가 구동 중이나 보안 설정(NTLM 강제)을 확인할 수 없습니다."
            $color = "Red"
        }
    }
} catch {
    $result = "오류"
    $statusMsg = "점검 중 에러 발생: $($_.Exception.Message)"
    $color = "Yellow"
}

# 4. 결과 객체 생성
$report = [PSCustomObject]@{
    "Category"       = $category
    "Code"           = $code
    "Risk Level"     = $riskLevel
    "Diagnosis Item" = $diagnosisItem
    "Result"         = $result
    "Current Status" = $statusMsg
    "Remedial Action"= $remedialAction
}

# 5. 콘솔 출력 및 CSV 저장
Write-Host "[결과] : $result" -ForegroundColor $color
Write-Host "[현황] : $statusMsg"
Write-Host "------------------------------------------------"

$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray