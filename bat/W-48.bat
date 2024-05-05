@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for SNMP allowed managers settings audit
set "csvFile=!resultDir!\SNMP_Allowed_Managers_Audit.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define audit details
set "category=계정관리"
set "code=W-48"
set "riskLevel=상"
set "diagnosisItem=SNMP 허용된 관리자 설정"
set "service=SNMP"
set "diagnosisResult=양호"
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-48] SNMP 허용된 관리자 설정 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 허용된 관리자가 구성되어 있습니다. >> "!TMP1!"
echo [경고]: 허용된 관리자가 명확하게 구성되지 않았습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: SNMP 허용된 관리자 설정 검사 (PowerShell 사용)
powershell -Command "& {
    $snmpService = Get-Service -Name SNMP -ErrorAction SilentlyContinue;
    if ($snmpService.Status -eq 'Running') {
        $permittedManagers = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers' -ErrorAction SilentlyContinue;
        if ($permittedManagers -and $permittedManagers.PSObject.Properties.Value) {
            $status = 'OK: SNMP 서비스가 실행 중이며 허용된 관리자가 구성되어 있습니다.'
        } else {
            $status = 'WARN: SNMP 서비스가 실행 중이지만 허용된 관리자가 명확하게 구성되지 않았습니다.'
        }
    } else {
        $status = 'INFO: SNMP 서비스가 실행되지 않고 있습니다.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p status=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\SNMP_Allowed_Managers_Audit.csv에서 확인하세요.
echo.

endlocal
pause
