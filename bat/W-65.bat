@echo off
SETLOCAL EnableDelayedExpansion

:: Request Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    PowerShell -Command "Start-Process cmd.exe -ArgumentList '/c %~f0' -Verb RunAs" -Wait
    exit
)

:: Set console environment
chcp 437 >nul
color 2A
cls
echo Setting up the environment...

:: Define directory variables
set "category=Security Management"
set "code=W-65"
set "riskLevel=High"
set "diagnosisItem=Allow Shutdown Without Logon"
set "diagnosisResult=Good"
set "status="
set "action=Adjust Shutdown Without Logon Policy"

set "computerName=%COMPUTERNAME%"
set "resultDir=C:\Windows_Security_Audit\%computerName%_result"

:: Create and clean directories
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%resultDir%"

:: Check the policy for "Shutdown without logon"
for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ShutdownWithoutLogon') do set shutdownWithoutLogon=%%a

if "!shutdownWithoutLogon!"=="0x1" (
    set "diagnosisResult=Vulnerable"
    set "status=System allows shutdown without logon."
) else (
    set "diagnosisResult=Secure"
    set "status=System does not allow shutdown without logon."
)

:: Save results in CSV format
echo Category,Code,Risk Level,Diagnosis Item,Diagnosis Result,Status,Action > "%resultDir%\%code%.csv"
echo %category%,%code%,%riskLevel%,%diagnosisItem%,%diagnosisResult%,%status%,%action% >> "%resultDir%\%code%.csv"

echo Audit complete. Results can be found in %resultDir%\%code%.csv.
echo.

ENDLOCAL
pause
