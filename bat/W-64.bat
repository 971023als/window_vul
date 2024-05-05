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
set "code=W-64"
set "riskLevel=High"
set "diagnosisItem=Screen Saver Settings"
set "diagnosisResult=Good"
set "status="
set "action=Adjust Screen Saver Settings"

set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Windows_Security_Audit\%computerName%_raw"
set "resultDir=C:\Windows_Security_Audit\%computerName%_result"

:: Create and clean directories
if not exist "%rawDir%" mkdir "%rawDir%"
if not exist "%resultDir%" mkdir "%resultDir%"

:: Check screen saver settings
for /f "tokens=3 delims= " %%a in ('reg query "HKCU\Control Panel\Desktop" /v ScreenSaveActive') do set ScreenSaveActive=%%a
for /f "tokens=3 delims= " %%b in ('reg query "HKCU\Control Panel\Desktop" /v ScreenSaverIsSecure') do set ScreenSaverIsSecure=%%b
for /f "tokens=3 delims= " %%c in ('reg query "HKCU\Control Panel\Desktop" /v ScreenSaveTimeOut') do set ScreenSaveTimeOut=%%c

if "!ScreenSaveActive!"=="1" (
    if "!ScreenSaverIsSecure!"=="1" (
        if !ScreenSaveTimeOut! lss 600 (
            set "diagnosisResult=Vulnerable"
            set "status=Screen saver is active but timeout is set to less than 10 minutes."
        ) else (
            set "status=Screen saver settings are adequately configured."
        )
    ) else (
        set "diagnosisResult=Vulnerable"
        set "status=Screen saver is set without requiring secure logon."
    )
) else (
    set "diagnosisResult=Vulnerable"
    set "status=Screen saver is disabled."
)

:: Save results in CSV format
echo Category,Code,Risk Level,Diagnosis Item,Diagnosis Result,Status,Action > "%resultDir%\%code%.csv"
echo %category%,%code%,%riskLevel%,%diagnosisItem%,%diagnosisResult%,%status%,%action% >> "%resultDir%\%code%.csv"

echo Audit complete. Results can be found in %resultDir%\%code%.csv.
echo.

ENDLOCAL
pause
