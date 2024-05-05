@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for LimitBlankPasswordUse policy analysis
set "csvFile=!resultDir!\Limit_Blank_Password_Use_Policy.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=계정관리"
set "code=W-17"
set "riskLevel=상"
set "diagnosisItem=콘솔 로그온 시 로컬 계정에서 빈 암호 사용 제한"
set "service=보안 정책"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-17] 'LimitBlankPasswordUse' 정책 설정 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [준수]: 'LimitBlankPasswordUse' 정책이 올바르게 적용됨. >> "!TMP1!"
echo [준수하지 않음]: 'LimitBlankPasswordUse' 정책이 올바르게 적용되지 않음. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 'LimitBlankPasswordUse' 정책 설정 검사
for /f "tokens=2 delims== eol= " %%a in ('findstr /R "LimitBlankPasswordUse = [0-9]*" "%rawPath%\Local_Security_Policy.txt"') do (
    set "limitBlankPasswordUse=%%a"
    if "!limitBlankPasswordUse!"=="1" (
        set "diagnosisResult=준수"
        set "status=준수 확인됨: 'LimitBlankPasswordUse' 정책이 올바르게 적용됨."
    ) else (
        set "diagnosisResult=취약"
        set "status=준수하지 않음 감지됨: 'LimitBlankPasswordUse' 정책이 올바르게 적용되지 않음."
    )
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
