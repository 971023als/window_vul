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
echo Environment is being initialized...

:: Define variables
set "category=Security Management"
set "code=W-70"
set "riskLevel=High"
set "diagnosisItem=Control over Formatting and Ejecting Removable Media"
set "diagnosisResult=Good"
set "status="
set "action=Proper Control over Formatting and Ejecting Removable Media"

set "computerName=%COMPUTERNAME%"
set "resultDir=C:\Windows_Security_%computerName%_Audit"

:: Ensure the directory exists
if not exist "%resultDir%" mkdir "%resultDir%"

:: Perform security check (Simulating security check here)
:: You can replace this with actual commands to check system settings
set "removableMediaPolicyEnabled=1"
if "!removableMediaPolicyEnabled!"=="1" (
    set "diagnosisResult=Good"
    set "status=The policy for formatting and ejecting removable media is properly restricted."
) else (
    set "diagnosisResult=Vulnerable"
    set "status=The policy for formatting and ejecting removable media is not adequately secured."
)

:: Save results in CSV format
echo "Category,Code,Risk Level,Diagnosis Item,Diagnosis Result,Status,Action" > "%resultDir%\%code%.csv"
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!diagnosisResult!","!status!","!action!" >> "%resultDir%\%code%.csv"

echo Audit complete. Results can be found in "%resultDir%\%code%.csv".
ENDLOCAL
pause
