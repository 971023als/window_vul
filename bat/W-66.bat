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
set "code=W-66"
set "riskLevel=High"
set "diagnosisItem=Remote System Shutdown Configuration"
set "diagnosisResult=Good"
set "status="
set "action=Configure policies to properly allow or deny remote system shutdown"

set "computerName=%COMPUTERNAME%"
set "resultDir=C:\Windows_Security_Audit\%computerName%_result"

:: Create and clean directories
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%resultDir%"

:: Check the remote system shutdown settings
for /f "tokens=2,*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v SeRemoteShutdownPrivilege') do (
    set permission=%%b
)

:: Analyze and record results
if "!permission!"=="S-1-5-32-544" (
    set "diagnosisResult=Vulnerable"
    set "status=Remote shutdown privilege is assigned only to the Administrators group."
) else (
    set "status=Remote shutdown privilege is configured securely."
)

:: Save results in CSV format
echo Category,Code,Risk Level,Diagnosis Item,Diagnosis Result,Status,Action > "%resultDir%\%code%.csv"
echo %category%,%code%,%riskLevel%,%diagnosisItem%,%diagnosisResult%,%status%,%action% >> "%resultDir%\%code%.csv"

echo Audit complete. Results can be found in %resultDir%\%code%.csv.
ENDLOCAL
pause
