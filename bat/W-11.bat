@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for maximum password age policy analysis
set "csvFile=!resultDir!\Maximum_Password_Age_Policy.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=계정관리"
set "code=W-11"
set "riskLevel=상"
set "diagnosisItem=패스워드 최대 사용 기간"
set "service=보안 정책"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-11] 패스워드 최대 사용 기간 설정 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 최대 암호 사용 기간 정책이 준수됩니다. >> "!TMP1!"
echo [취약]: 최대 암호 사용 기간 정책이 준수되지 않습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 패스워드 최대 사용 기간 설정 검사
for /f "tokens=2 delims== eol= " %%a in ('findstr /R "MaximumPasswordAge = [0-9]*" "%rawPath%\Local_Security_Policy.txt"') do (
    set "maximumPasswordAge=%%a"
    if !maximumPasswordAge! leq 90 (
        set "diagnosisResult=양호"
        set "status=최대 암호 사용 기간 정책이 준수됩니다. !maximumPasswordAge!일로 설정됨."
    ) else (
        set "diagnosisResult=취약"
        set "status=최대 암호 사용 기간 정책이 준수되지 않습니다. !maximumPasswordAge!일로 설정됨."
    )
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
