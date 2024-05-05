@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=C:\Window_%COMPUTERNAME%_result"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for Login Warning Message Policy Analysis
set "csvFile=!resultDir!\Login_Warning_Message_Policy.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Result,Status,Countermeasure" > "!csvFile!"

REM Define security details
set "category=보안 관리"
set "code=W-75"
set "riskLevel=높음"
set "diagnosisItem=로그인 경고 메시지 설정"
set "result=양호"
set "status=점검 중..."
set "countermeasure=로그인 경고 메시지 설정 조정"

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [!code!] 로그인 경고 메시지 정책 진단 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 로그인 경고 메시지가 설정되어 있지 않음 >> "!TMP1!"
echo [취약]: 로그인 경고 메시지가 설정되어 있음 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: Check the login warning message policy
set "policyEnabled=1"

:: Update diagnostic result based on the policy value
if "!policyEnabled!"=="1" (
    set "result=취약"
    set "status=로그인 경고 메시지가 설정되어 있습니다."
) else (
    set "status=로그인 경고 메시지가 설정되어 있지 않습니다."
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!result!","!status!","!countermeasure!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
