@echo off
SETLOCAL EnableDelayedExpansion

:: Check and request administrative privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    PowerShell -Command "Start-Process cmd.exe -ArgumentList '/c %~f0' -Verb RunAs" -Wait
    exit
)

:: Set console environment
chcp 437 >nul
color 2A
cls
echo Initializing environment...

:: Define variables for CSV output
set "category=Security Management"
set "code=W-68"
set "riskLevel=High"
set "diagnosisItem=Disallow Anonymous Enumeration of SAM Accounts and Shares"
set "diagnosisResult=Good"
set "status="
set "action=Configure system policy to disallow anonymous enumeration"

set "computerName=%COMPUTERNAME%"
set "resultDir=C:\Windows_Security_Audit\%computerName%_results"

:: Create and clean directories
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%resultDir%"

:: Check the system policy regarding anonymous enumeration
for /f "tokens=2,*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\LSA" /v restrictanonymous') do set "restrictanonymous=%%b"
for /f "tokens=2,*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\LSA" /v RestrictAnonymousSAM') do set "RestrictAnonymousSAM=%%b"

:: Analyze and record results
if "!restrictanonymous!"=="1" and "!RestrictAnonymousSAM!"=="1" (
    set "status=The system is properly configured to restrict anonymous enumeration of SAM accounts and shares."
) else (
    set "diagnosisResult=Vulnerable"
    set "status=The system is not properly configured to restrict anonymous enumeration of SAM accounts and shares."
)

:: Save results in CSV format
echo Category,Code,Risk Level,Diagnosis Item,Diagnosis Result,Status,Action > "%resultDir%\%code%.csv"
echo %category%,%code%,%riskLevel%,%diagnosisItem%,%diagnosisResult%,%status%,%action% >> "%resultDir%\%code%.csv"

echo Audit complete. Results can be found in %resultDir%\%code%.csv.
ENDLOCAL
pause
