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
echo Initializing environment...

:: Variables
set "category=Security Management"
set "code=W-67"
set "riskLevel=High"
set "diagnosisItem=System Shutdown on Audit Failure"
set "diagnosisResult=Good"
set "status="
set "action=Configure policy to shut down the system if security audits cannot be recorded"

set "computerName=%COMPUTERNAME%"
set "resultDir=C:\Window_%computerName%_results"

:: Create and clean directories
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%resultDir%"

:: Check the policy for "Crash on Audit Fail"
for /f "tokens=2,*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v CrashOnAuditFail') do (
    set policy=%%b
)

:: Analyze and record results
if "!policy!"=="0x1" (
    set "diagnosisResult=Good"
    set "status=The system is configured to shut down if security audits cannot be recorded, enhancing security."
) else (
    set "diagnosisResult=Vulnerable"
    set "status=The system is not configured to shut down when security audits fail, posing a security risk."
)

:: Save results in CSV format
echo Category,Code,Risk Level,Diagnosis Item,Diagnosis Result,Status,Action > "%resultDir%\%code%.csv"
echo %category%,%code%,%riskLevel%,%diagnosisItem%,%diagnosisResult%,%status%,%action% >> "%resultDir%\%code%.csv"

echo Audit complete. Results can be found in %resultDir%\%code%.csv.
ENDLOCAL
pause
