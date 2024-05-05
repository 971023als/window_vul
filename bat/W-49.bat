@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for DNS dynamic update status analysis
set "csvFile=!resultDir!\DNS_Dynamic_Update_Status.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define audit details
set "category=서비스관리"
set "code=W-49"
set "riskLevel=상"
set "diagnosisItem=DNS 서비스 동적 업데이트 점검"
set "service=DNS"
set "diagnosisResult=양호"
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-49] DNS 서비스 동적 업데이트 설정 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: DNS 서비스가 동적 업데이트를 허용하지 않습니다. >> "!TMP1!"
echo [경고]: DNS 서비스가 동적 업데이트를 허용합니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: DNS 서비스 동적 업데이트 설정 검사 (PowerShell 사용)
powershell -Command "& {
    $dnsService = Get-Service -Name 'DNS' -ErrorAction SilentlyContinue;
    if ($dnsService.Status -eq 'Running') {
        $zones = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\DNS Server\Zones' -ErrorAction SilentlyContinue;
        if ($zones) {
            $allowUpdate = $zones.AllowUpdate;
            if ($allowUpdate -eq 0) {
                $status = 'OK: DNS 서비스가 활성화되어 있으나 동적 업데이트 권한이 설정되어 있지 않아 안전합니다.'
            } else {
                $status = 'WARN: DNS 서비스가 활성화되어 있으나 동적 업데이트 권한이 설정되어 위험합니다.'
            }
        } else {
            $status = 'INFO: DNS 설정을 불러올 수 없습니다.'
        }
    } else {
        $status = 'OK: DNS 서비스가 비활성화되어 있습니다.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p status=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\DNS_Dynamic_Update_Status.csv에서 확인하세요.
echo.

endlocal
pause
