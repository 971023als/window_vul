@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for security policy analysis regarding anonymous inclusion
set "csvFile=!resultDir!\Everyone_Includes_Anonymous_Policy.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=계정관리"
set "code=W-07"
set "riskLevel=상"
set "diagnosisItem=Everyone 사용 권한을 익명 사용자에게 적용"
set "service=보안 정책"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-07] 'EveryoneIncludesAnonymous' 정책 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: '모든 사용자가 익명 사용자를 포함' 정책이 '사용 안 함'으로 올바르게 설정되어 있습니다. >> "!TMP1!"
echo [취약]: '모든 사용자가 익명 사용자를 포함' 정책이 '사용'으로 설정되어 잠재적 보안 위험을 초래합니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 'EveryoneIncludesAnonymous' 정책 검사
for /f "tokens=2 delims==" %%a in ('findstr /C:"EveryoneIncludesAnonymous =" "%rawPath%\Local_Security_Policy.txt"') do (
    set "everyoneIncludesAnonymous=%%a"
    if "!everyoneIncludesAnonymous!"=="0" (
        set "diagnosisResult=양호"
        set "status='모든 사용자가 익명 사용자를 포함' 정책이 '사용 안 함'으로 올바르게 설정되어 더 높은 보안을 보장합니다."
    ) else (
        set "diagnosisResult=취약"
        set "status='모든 사용자가 익명 사용자를 포함' 정책이 '사용'으로 설정되어 잠재적 보안 위험을 초래합니다."
    )
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
