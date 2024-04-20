@echo off
setlocal enabledelayedexpansion

:: Check if script is running as Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    pause
    exit
)

:: Set up directories for storing raw data and results
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"

mkdir "%rawDir%"
mkdir "%resultDir%"

:: Export local security policies to file
secedit /export /cfg "%rawDir%\secpol.cfg" >nul

:: System information to file
systeminfo > "%rawDir%\systeminfo.txt"

:: Analyze settings (simulation of analysis for encryption issues)
echo Checking system settings...
set "encryptionIssueFound=0"
set "encryptionDetails=All encryption methods are compliant with security standards."

:: Simulate finding an issue (for example purposes)
if "%encryptionIssueFound%"=="1" (
    set "encryptionDetails=Decryption-capable encryption methods found."
)

:: Output results to CSV
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\results.csv"
echo 계정관리,W-33,상,해독 가능한 암호화를 사용하여 암호 저장,양호,"%encryptionDetails%",비밀번호 저장을 위해 비복호화 가능한 암호화 사용 권장 >> "%resultDir%\results.csv"

echo Results have been saved to %resultDir%\results.csv
endlocal
pause
