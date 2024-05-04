@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for minimum password length policy analysis
set "csvFile=!resultDir!\Minimum_Password_Length_Policy.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=계정관리"
set "code=W-10"
set "riskLevel=상"
set "diagnosisItem=패스워드 최소 암호 길이"
set "service=보안 정책"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-10] 패스워드 최소 암호 길이 설정 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 패스워드 최소 암호 길이가 8자 이상으로 적절하게 설정되어 있습니다. >> "!TMP1!"
echo [취약]: 패스워드 최소 암호 길이가 8자 미만으로 설정되어 있습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 패스워드 최소 길이 설정 검사
for /f "tokens=2 delims==" %%a in ('findstr /C:"MinimumPasswordLength =" "%rawPath%\Local_Security_Policy.txt"') do (
    set "minPasswordLength=%%a"
    if !minPasswordLength! geq 8 (
        set "diagnosisResult=양호"
        set "status=패스워드 최소 암호 길이가 8자 이상으로 적절하게 설정되어 있습니다."
    ) else (
        set "diagnosisResult=취약"
        set "status=패스워드 최소 암호 길이가 8자 미만으로 설정되어 있습니다."
    )
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
