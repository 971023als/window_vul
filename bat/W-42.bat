@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for RDS service audit
set "csvFile=!resultDir!\RDS_Service_Audit.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define audit details
set "category=계정관리"
set "code=W-42"
set "riskLevel=상"
set "diagnosisItem=RDS(Remote Data Services) 제거"
set "service=RDS"
set "diagnosisResult=양호"
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-42] RDS 제거 상태 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 웹 서비스가 실행되지 않거나 설치되지 않았습니다. >> "!TMP1!"
echo [위험]: 웹 서비스가 실행 중입니다. RDS가 활성화되어 있을 수 있습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: RDS 상태 점검 (PowerShell 사용)
powershell -Command "& {
    $webService = Get-Service -Name 'W3SVC' -ErrorAction SilentlyContinue;
    if ($webService -and $webService.Status -eq 'Running') {
        $status = 'WARN: 웹 서비스가 실행 중입니다. RDS가 활성화되어 있을 수 있습니다.'
    } else {
        $status = 'OK: 웹 서비스가 실행되지 않거나 설치되지 않았습니다.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p status=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\RDS_Service_Audit.csv에서 확인하세요.
echo.

endlocal
pause
