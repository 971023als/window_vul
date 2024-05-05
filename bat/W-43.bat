@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for OS Service Pack audit
set "csvFile=!resultDir!\OS_Service_Pack_Audit.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define audit details
set "category=서비스관리"
set "code=W-43"
set "riskLevel=상"
set "diagnosisItem=최신 서비스팩 적용"
set "service=Operating System"
set "diagnosisResult=양호"
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-43] OS 최신 서비스팩 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 최신 서비스팩이 적용되어 있습니다. >> "!TMP1!"
echo [취약]: 최신 서비스팩이 적용되지 않았습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: OS 버전 및 서비스팩 진단 (PowerShell 사용)
powershell -Command "& {
    $osInfo = Get-CimInstance Win32_OperatingSystem
    $osVersion = $osInfo.Version
    $servicePack = $osInfo.ServicePackMajorVersion

    if ($servicePack -eq 0) {
        $status = 'WARN: 최신 서비스팩이 적용되지 않았습니다.'
    } else {
        $status = 'OK: 최신 서비스팩이 적용되어 있습니다.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p status=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\OS_Service_Pack_Audit.csv에서 확인하세요.
echo.

endlocal
pause
