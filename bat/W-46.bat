@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for SNMP service audit
set "csvFile=!resultDir!\SNMP_Service_Status.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define audit details
set "category=서비스관리"
set "code=W-46"
set "riskLevel=상"
set "diagnosisItem=SNMP 서비스 구동 점검"
set "service=SNMP"
set "diagnosisResult=양호"
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-46] SNMP 서비스 구동 상태 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: SNMP 서비스가 실행되지 않고 있습니다. >> "!TMP1!"
echo [경고]: SNMP 서비스가 활성화되어 있습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: SNMP 서비스 상태 검사 (PowerShell 사용)
powershell -Command "& {
    $snmpService = Get-Service -Name 'SNMP' -ErrorAction SilentlyContinue;
    if ($snmpService -and $snmpService.Status -eq 'Running') {
        $status = 'WARN: SNMP 서비스가 활성화되어 있습니다. 이는 보안상 위험할 수 있으므로, 필요하지 않은 경우 비활성화하는 것이 권장됩니다.'
    } else {
        $status = 'OK: SNMP 서비스가 실행되지 않고 있습니다. 이는 추가 보안을 위한 긍정적인 상태입니다.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p diagnosisResult=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\SNMP_Service_Status.csv에서 확인하세요.
echo.

endlocal
pause
