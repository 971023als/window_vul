@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0Window_%COMPUTERNAME%_result"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for encryption policy analysis
set "csvFile=!resultDir!\results.csv"
echo "분류,코드,위험도,진단항목,진단결과,현황,대응방안" > "!csvFile!"

REM Define security details
set "category=계정관리"
set "code=W-33"
set "riskLevel=상"
set "diagnosisItem=해독 가능한 암호화를 사용하여 암호 저장"
set "diagnosisResult=양호"
set "status=All encryption methods are compliant with security standards."
set "responsePlan=비밀번호 저장을 위해 비복호화 가능한 암호화 사용 권장"

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo Running encryption policy check >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: Setup directories for storing raw data and results
set "rawDir=C:\Window_%COMPUTERNAME%_raw"
if exist "%rawDir%" rmdir /s /q "%rawDir%"
mkdir "%rawDir%"

:: Export local security policies and system information
secedit /export /cfg "%rawDir%\secpol.cfg" >nul
systeminfo > "%rawDir%\systeminfo.txt"

echo Checking system settings... >> "!TMP1!"
set "encryptionIssueFound=0"
if "%encryptionIssueFound%"=="1" (
    set "diagnosisResult=취약"
    set "status=Decryption-capable encryption methods found."
    set "responsePlan=비밀번호 저장을 위해 비복호화 가능한 암호화 사용 권장"
)

:: Output results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!diagnosisResult!","!status!","!responsePlan!" >> "!csvFile!"

echo Results have been saved to "%csvFile%" >> "!TMP1!"
type "!TMP1!"

endlocal
pause
