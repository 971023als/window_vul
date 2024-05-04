@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for user account status analysis
set "csvFile=!resultDir!\User_Account_Status.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=계정관리"
set "code=W-03"
set "riskLevel=상"
set "diagnosisItem=불필요한 계정 제거"
set "service=사용자 계정"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-03] 불필요한 계정 제거 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 모든 사용자 계정이 필요하며 활성화되어 있지 않은 경우 >> "!TMP1!"
echo [취약]: 불필요하게 활성화된 사용자 계정이 있는 경우 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 사용자 계정 상태 분석
set "status=양호"
for /f "skip=4 delims=" %%i in ('type "%rawPath%\users.txt"') do (
    set "line=%%i"
    for %%u in (!line!) do (
        net user %%u > "%rawPath%\user_%%u.txt"
        findstr /C:"Account active               Yes" "%rawPath%\user_%%u.txt" >nul && (
            set "diagnosisResult=취약"
            set "status=!status!활성화된 계정: %%u; "
        )
    )
)

if "!status!"=="양호" (
    set "status=모든 사용자 계정이 필요하며 활성화되어 있지 않습니다."
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
