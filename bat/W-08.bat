@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for account lockout policy analysis
set "csvFile=!resultDir!\Account_Lockout_Policy.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=계정관리"
set "code=W-08"
set "riskLevel=상"
set "diagnosisItem=계정 잠금 기간 설정"
set "service=보안 정책"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-08] 계정 잠금 기간 설정 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: '잠금 지속 시간'과 '잠금 카운트 리셋 시간'이 설정 요구사항을 충족합니다. >> "!TMP1!"
echo [취약]: '잠금 지속 시간' 또는 '잠금 카운트 리셋 시간'이 설정 요구사항을 미충족합니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 계정 잠금 기간 설정 검사
for /f "tokens=2 delims==" %%a in ('findstr /C:"LockoutDuration =" "%rawPath%\Local_Security_Policy.txt"') do set "lockoutDuration=%%a"
for /f "tokens=2 delims==" %%b in ('findstr /C:"ResetLockoutCount =" "%rawPath%\Local_Security_Policy.txt"') do set "resetLockoutCount=%%b"

if %resetLockoutCount% gtr 59 (
    if %lockoutDuration% gtr 59 (
        set "diagnosisResult=양호"
        set "status=정책 충족: '잠금 지속 시간'과 '잠금 카운트 리셋 시간'이 설정 요구사항을 충족합니다."
    ) else (
        set "diagnosisResult=취약"
        set "status=정책 미충족: '잠금 지속 시간' 또는 '잠금 카운트 리셋 시간'이 설정 요구사항을 미충족합니다."
    )
) else (
    set "diagnosisResult=취약"
    set "status=정책 미충족: '잠금 지속 시간' 또는 '잠금 카운트 리셋 시간'이 설정 요구사항을 미충족합니다."
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
