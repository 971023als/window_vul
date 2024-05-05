@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for password history policy analysis
set "csvFile=!resultDir!\Password_History_Policy.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=계정관리"
set "code=W-16"
set "riskLevel=상"
set "diagnosisItem=최근 암호 기억"
set "service=보안 정책"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-16] 비밀번호 기억 정책 설정 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [준수]: 비밀번호 이력 크기가 11개 이전 비밀번호를 초과하도록 설정됨. >> "!TMP1!"
echo [준수하지 않음]: 비밀번호 이력 크기가 11개 이전 비밀번호를 초과하지 않음. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 비밀번호 기억 정책 설정 검사
for /f "tokens=2 delims== eol= " %%a in ('findstr /R "PasswordHistorySize = [0-9]*" "%rawPath%\Local_Security_Policy.txt"') do (
    set "passwordHistorySize=%%a"
    if !passwordHistorySize! gtr 11 (
        set "diagnosisResult=준수"
        set "status=준수 확인됨: 비밀번호 이력 크기가 11개 이전 비밀번호를 초과하도록 설정됨."
    ) else (
        set "diagnosisResult=취약"
        set "status=준수하지 않음 감지됨: 비밀번호 이력 크기가 11개 이전 비밀번호를 초과하지 않음."
    )
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
