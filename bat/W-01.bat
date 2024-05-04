@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0result"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for administrator account name check
set "csvFile=!resultDir!\Admin_Account_Name_Check.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Result,Current Status,Remedial Action" > "!csvFile!"

REM Define security details
set "category=계정관리"
set "code=W-01"
set "riskLevel=상"
set "diagnosisItem=Administrator 계정 이름 바꾸기"
set "result="
set "diagnosisResult="
set "remedialAction=Administrator 계정 이름 변경"

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-01] 관리자 계정 이름 변경 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 관리자 계정 이름이 변경되어 있는 경우 >> "!TMP1!"
echo [취약]: 관리자 계정의 기본 이름이 변경되지 않았습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 관리자 계정 이름 변경 확인
findstr "NewAdministratorName" "%rawPath%\Local_Security_Policy.txt" >nul || (
    set "result=취약"
    set "currentStatus=관리자 계정의 기본 이름이 변경되지 않았습니다."
)

if not defined result (
    set "result=양호"
    set "currentStatus=관리자 계정 이름이 변경되어 있습니다."
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!result!","!currentStatus!","!remedialAction!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
