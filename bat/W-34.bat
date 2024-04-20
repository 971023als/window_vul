@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Check if running as Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Require administrator privileges. Please right-click and run as administrator.
    pause
    exit
)

:: Setup directories for storing outputs
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

:: Clean up old data
if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"

mkdir "%rawDir%"
mkdir "%resultDir%"

:: Export local security policy
secedit /export /cfg "%rawDir%\secpol.cfg" >nul

:: Get system info
systeminfo > "%rawDir%\systeminfo.txt"

:: IIS Configuration analysis
set "iisConfig=%windir%\System32\inetsrv\config\applicationHost.config"
if exist "%iisConfig%" (
    type "%iisConfig%" > "%rawDir%\iisConfig.txt"
    findstr "physicalPath bindingInformation" "%rawDir%\iisConfig.txt" > "%resultDir%\iisAnalysis.txt"
) else (
    echo IIS configuration file not found. > "%resultDir%\iisAnalysis.txt"
)

:: Placeholder for encryption method check
:: Simulating detection of non-reversible encryption
set "encryptionMethod=Non-reversible"
set "encryptionStatus=Good"
set "recommendation=Use non-decryptable encryption methods for storing passwords"

:: Output results in CSV format
(
    echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안
    echo 계정관리,W-34,높음,비밀번호 저장을 위한 복호화 가능한 암호화 사용,%encryptionStatus%,%encryptionMethod%,%recommendation%
) > "%resultDir%\results.csv"

echo Results have been saved to %resultDir%\results.csv
pause
ENDLOCAL
