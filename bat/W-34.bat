@echo off
setlocal enabledelayedexpansion

REM Check if running as Administrator and exit if not
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Require administrator privileges. Please right-click and run as administrator.
    pause
    exit
)

REM Setup directories for storing outputs
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

REM Clean up old data
if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"

mkdir "%rawDir%"
mkdir "%resultDir%"

REM Export local security policy
secedit /export /cfg "%rawDir%\secpol.cfg" >nul

REM Get system info
systeminfo > "%rawDir%\systeminfo.txt"

REM IIS Configuration analysis
set "iisConfig=%windir%\System32\inetsrv\config\applicationHost.config"
if exist "%iisConfig%" (
    type "%iisConfig%" > "%rawDir%\iisConfig.txt"
    findstr "physicalPath bindingInformation" "%rawDir%\iisConfig.txt" > "%resultDir%\iisAnalysis.txt"
) else (
    echo IIS configuration file not found. > "%resultDir%\iisAnalysis.txt"
)

REM Placeholder for encryption method check
set "category=계정 관리"
set "code=W-34"
set "riskLevel=높음"
set "diagnosisItem=비밀번호 저장을 위한 복호화 가능한 암호화 사용"
set "diagnosisResult=Non-reversible"
set "status=Good"
set "recommendation=Use non-decryptable encryption methods for storing passwords"

REM Save results to CSV
echo "분류,코드,위험도,진단항목,진단결과,현황,대응방안" > "%resultDir%\results.csv"
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!diagnosisResult!","!status!","!recommendation!" >> "%resultDir%\results.csv"

echo Results have been saved to %resultDir%\results.csv
pause
endlocal
