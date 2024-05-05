@echo off
SETLOCAL EnableDelayedExpansion

:: Check and request administrative privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    PowerShell -Command "Start-Process cmd.exe -ArgumentList '/c %~f0' -Verb RunAs"
    exit
)

:: Set console environment
chcp 437 >nul
color 2A
cls
echo Initializing environment...

:: Define variables for output
set "category=Security Management"
set "code=W-69"
set "riskLevel=High"
set "diagnosisItem=Control of Automatic Logon Feature"
set "diagnosisResult=Good"
set "status="
set "action=Disable Automatic Logon to Enhance Security"

set "computerName=%COMPUTERNAME%"
set "resultDir=C:\Windows_%computerName%_security"

:: Ensure the directory exists
if not exist "%resultDir%" mkdir "%resultDir%"

:: Check registry for auto logon enabled
for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon') do set autoLogonEnabled=%%a

if "!autoLogonEnabled!"=="1" (
    set "diagnosisResult=Vulnerable"
    set "status=AutoAdminLogon is enabled, posing a security risk."
) else (
    set "status=AutoAdminLogon is disabled, enhancing system security."
)

:: Save results in CSV format
echo Category,Code,Risk Level,Diagnosis Item,Diagnosis Result,Status,Action > "%resultDir%\%code%.csv"
echo %category%,%code%,%riskLevel%,%diagnosisItem%,%diagnosisResult%,%status%,%action% >> "%resultDir%\%code%.csv"

echo Audit complete. Results can be found in %resultDir%\%code%.csv.
ENDLOCAL
pause
