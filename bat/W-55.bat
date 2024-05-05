@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for hotfix status analysis
set "csvFile=!resultDir!\Hotfix_Status.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=패치관리"
set "code=W-55"
set "riskLevel=상"
set "diagnosisItem=최신 HOT FIX 적용"
set "service=System Patch"
set "diagnosisResult=양호"
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-55] 최신 HOT FIX 적용 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 최신 핫픽스가 설치되어 있습니다. >> "!TMP1!"
echo [취약]: 최신 핫픽스가 설치되어 있지 않습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: Check for hotfix installation (Using PowerShell)
powershell -Command "& {
    $hotfixId = 'KB3214628'
    $hotfixCheck = Get-HotFix -Id $hotfixId -ErrorAction SilentlyContinue
    if ($hotfixCheck) {
        $status = 'OK: 핫픽스 $hotfixId이 설치되어 있습니다.'
    } else {
        $status = 'WARN: 핫픽스 $hotfixId이 설치되어 있지 않습니다.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p diagnosisResult=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\Hotfix_Status.csv에서 확인하세요.
echo.

endlocal
pause
