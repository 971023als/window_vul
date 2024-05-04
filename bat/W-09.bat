@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for password complexity policy analysis
set "csvFile=!resultDir!\Password_Complexity_Policy.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=계정관리"
set "code=W-09"
set "riskLevel=상"
set "diagnosisItem=패스워드 복잡성 설정"
set "service=보안 정책"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-09] 패스워드 복잡성 설정 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 패스워드 복잡성 정책이 적절히 설정되어 있습니다. >> "!TMP1!"
echo [취약]: 패스워드 복잡성 정책이 적절히 설정되지 않았습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 패스워드 복잡성 설정 검사
for /f "tokens=2 delims==" %%a in ('findstr /C:"PasswordComplexity =" "%rawPath%\Local_Security_Policy.txt"') do (
    set "passwordComplexity=%%a"
    if "!passwordComplexity!"=="1" (
        set "diagnosisResult=양호"
        set "status=패스워드 복잡성 정책이 적절히 설정되어 있습니다."
    ) else (
        set "diagnosisResult=취약"
        set "status=패스워드 복잡성 정책이 적절히 설정되지 않았습니다."
    )
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
