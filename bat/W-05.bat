@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for reversible encryption policy analysis
set "csvFile=!resultDir!\Reversible_Encryption_Policy.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=계정관리"
set "code=W-05"
set "riskLevel=상"
set "diagnosisItem=해독 가능한 암호화를 사용하여 암호 저장"
set "service=보안 정책"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-05] 해독 가능한 암호화를 사용하여 암호 저장 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 가역 암호화를 사용하여 비밀번호 저장 정책이 '사용 안 함'으로 설정되어 있습니다. >> "!TMP1!"
echo [취약]: 가역 암호화를 사용하여 비밀번호 저장 정책이 적절히 구성되지 않았습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 가역 암호화 정책 검사
for /f "tokens=2 delims==" %%a in ('findstr /C:"ClearTextPassword =" "%rawPath%\Local_Security_Policy.txt"') do (
    set "clearTextPassword=%%a"
    if "!clearTextPassword!"=="0" (
        set "diagnosisResult=양호"
        set "status=가역 암호화를 사용하여 비밀번호 저장 정책이 '사용 안 함'으로 설정되어 있습니다."
    ) else (
        set "diagnosisResult=취약"
        set "status=가역 암호화를 사용하여 비밀번호 저장 정책이 적절히 구성되지 않았습니다."
    )
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
