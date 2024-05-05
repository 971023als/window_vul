@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for local logon permissions policy analysis
set "csvFile=!resultDir!\Local_Logon_Permissions_Policy.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=계정관리"
set "code=W-14"
set "riskLevel=상"
set "diagnosisItem=로컬 로그온 허용"
set "service=보안 정책"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-14] 로컬 로그온 허용 정책 설정 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 로컬 로그온 허용 정책이 관리자와 IUSR 계정에 대해 구성되어 있습니다. >> "!TMP1!"
echo [취약]: 로컬 로그온 허용 정책이 예상대로 구성되지 않아 잠재적 보안 위험을 초래합니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 로컬 로그온 허용 정책 설정 검사
for /f "delims=" %%a in ('findstr "SeInteractiveLogonRight" "%rawPath%\Local_Security_Policy.txt"') do (
    set "interactiveLogonRight=%%a"
    if not "!interactiveLogonRight!"=="" (
        set "diagnosisResult=양호"
        set "status=로컬 로그온 허용 정책이 관리자와 IUSR 계정에 대해 구성되어 있습니다."
    ) else (
        set "diagnosisResult=취약"
        set "status=로컬 로그온 허용 정책이 예상대로 구성되지 않아 잠재적 보안 위험을 초래합니다."
    )
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
