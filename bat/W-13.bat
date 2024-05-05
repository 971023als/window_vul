@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for the last user name display policy analysis
set "csvFile=!resultDir!\Last_UserName_Display_Policy.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=계정관리"
set "code=W-13"
set "riskLevel=상"
set "diagnosisItem=마지막 사용자 이름 표시 안함"
set "service=보안 정책"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-13] 마지막으로 로그온한 사용자 이름 표시 정책 설정 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [준수]: 마지막으로 로그온한 사용자 이름을 표시하지 않는 정책이 활성화되어 있습니다. >> "!TMP1!"
echo [미준수]: 마지막으로 로그온한 사용자 이름을 표시하지 않는 정책이 비활성화되어 있습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 마지막 사용자 이름 표시 정책 설정 검사
for /f "tokens=2 delims== eol= " %%a in ('findstr /R "DontDisplayLastUserName = [0-9]*" "%rawPath%\Local_Security_Policy.txt"') do (
    set "dontDisplayLastUserName=%%a"
    if "!dontDisplayLastUserName!"=="1" (
        set "diagnosisResult=준수"
        set "status=마지막으로 로그온한 사용자 이름을 표시하지 않는 정책이 활성화되어 있습니다."
    ) else (
        set "diagnosisResult=취약"
        set "status=마지막으로 로그온한 사용자 이름을 표시하지 않는 정책이 비활성화되어 있습니다."
    )
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
