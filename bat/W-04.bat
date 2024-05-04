@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for account lockout threshold analysis
set "csvFile=!resultDir!\Account_Lockout_Threshold.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=계정관리"
set "code=W-04"
set "riskLevel=상"
set "diagnosisItem=계정 잠금 임계값 설정"
set "service=보안 정책"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-04] 계정 잠금 임계값 설정 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 계정 잠금 임계값이 준수 범위 내에 설정되었습니다. >> "!TMP1!"
echo [취약]: 계정 잠금 임계값이 설정되지 않았거나 너무 높게 설정되어 있습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 계정 잠금 임계값 검사
set "lockoutThreshold=0"
for /f "tokens=2 delims==" %%a in ('findstr /C:"LockoutBadCount =" "%rawPath%\Local_Security_Policy.txt"') do set "lockoutThreshold=%%a"

if %lockoutThreshold% gtr 5 (
    set "diagnosisResult=취약"
    set "status=계정 잠금 임계값이 5회 시도보다 많게 설정되어 있습니다."
) else if %lockoutThreshold% equ 0 (
    set "diagnosisResult=취약"
    set "status=계정 잠금 임계값이 설정되지 않았습니다(없음)."
) else (
    set "diagnosisResult=양호"
    set "status=계정 잠금 임계값이 준수 범위 내에 설정되었습니다."
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
