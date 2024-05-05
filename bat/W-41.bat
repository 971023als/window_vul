@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for DNS zone transfer audit
set "csvFile=!resultDir!\DNS_Zone_Transfer_Audit.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define audit details
set "category=서비스관리"
set "code=W-41"
set "riskLevel=상"
set "diagnosisItem=DNS Zone Transfer 설정"
set "service=DNS"
set "diagnosisResult=양호"
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-41] DNS Zone Transfer 설정 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: DNS 전송 설정이 안전하게 구성되어 있습니다. >> "!TMP1!"
echo [취약]: DNS 전송 설정이 취약한 구성으로 되어 있습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: DNS 보안 설정 점검 (PowerShell 사용)
powershell -Command "& {
    $dnsService = Get-Service 'DNS' -ErrorAction SilentlyContinue
    if ($dnsService.Status -eq 'Running') {
        $dnsZonesRegPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\DNS Server\Zones'
        $zoneKeys = Get-ChildItem -Path $dnsZonesRegPath -ErrorAction SilentlyContinue
        $zoneSecurityIssues = $false

        foreach ($zone in $zoneKeys) {
            $zoneData = Get-ItemProperty -Path $zone.PSPath -Name 'SecureSecondaries' -ErrorAction SilentlyContinue
            if ($zoneData -and $zoneData.SecureSecondaries -ne 2) {
                $zoneSecurityIssues = $true
                break
            }
        }

        if (-not $zoneSecurityIssues) {
            $status = 'OK: DNS 전송 설정이 안전하게 구성되어 있습니다.'
        } else {
            $status = 'WARN: DNS 전송 설정이 취약한 구성으로 되어 있습니다. DNS 전송 설정을 보안 강화를 위해 수정해야 합니다.'
        }
    } else {
        $status = 'INFO: DNS 서비스가 실행 중이지 않습니다.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p status=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\DNS_Zone_Transfer_Audit.csv에서 확인하세요.
echo.

endlocal
pause
