@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=C:\Window_%COMPUTERNAME%_result"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for LAN Manager Authentication Level Analysis
set "csvFile=!resultDir!\LAN_Manager_Auth_Level.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=보안관리"
set "code=W-77"
set "riskLevel=상"
set "diagnosisItem=LAN Manager 인증 수준"
set "service=LAN Manager"
set "diagnosisResult=양호"
set "status=점검 시작..."
set "countermeasure=LAN Manager 인증 수준 변경"

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [!code!] LAN Manager 인증 수준 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 인증 수준이 보안에 적합하게 설정되어 있습니다. >> "!TMP1!"
echo [취약]: 인증 수준이 보안 기준에 미치지 못합니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    PowerShell -Command "Start-Process cmd.exe -ArgumentList '/c %~f0' -Verb RunAs"
    exit
)

:: Perform the diagnostic check
echo Checking LAN Manager authentication level...
for /f "tokens=2*" %%a in ('reg query HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v LmCompatibilityLevel 2^>nul') do set lmLevel=%%b

:: Determine status based on the retrieved value
if defined lmLevel (
    if !lmLevel! geq 3 (
        set "status=LAN Manager 인증 수준이 보안에 적합하게 설정되어 있습니다."
    ) else (
        set "diagnosisResult=취약"
        set "status=LAN Manager 인증 수준이 보안 기준에 미치지 못합니다."
    )
) else (
    set "diagnosisResult=오류"
    set "status=LAN Manager 인증 수준을 확인할 수 없습니다."
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!","!countermeasure!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
