@echo off
SETLOCAL EnableDelayedExpansion

:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    PowerShell -Command "Start-Process cmd.exe -ArgumentList '/c %~f0' -Verb RunAs"
    exit
)

:: Set console environment
chcp 437 >nul
color 0A
cls
echo Setting up the environment...

:: Define variables
set "category=Security Management"
set "code=W-71"
set "riskLevel=High"
set "diagnosisItem=Disk Volume Encryption Settings"
set "diagnosisResult=Good"
set "status=Checking encryption status..."
set "action=Enhance data protection by configuring disk volume encryption"

:: Directory for storing the results
set "computerName=%COMPUTERNAME%"
set "resultDir=C:\Windows_Security_Audit\%computerName%_results"
if not exist "%resultDir%" mkdir "%resultDir%"

:: Check BitLocker status using PowerShell
for /f "tokens=*" %%i in ('PowerShell -Command "(Get-BitLockerVolume -MountPoint C:).ProtectionStatus"') do set "ProtectionStatus=%%i"

:: Update diagnostic result based on BitLocker status
if "!ProtectionStatus!"=="1" (
    set "status=The C: drive is encrypted with BitLocker."
) else (
    set "diagnosisResult=Vulnerable"
    set "status=The C: drive is not encrypted with BitLocker."
)

:: Save results to CSV
echo "Category,Code,Risk Level,Diagnosis Item,Diagnosis Result,Status,Action" > "%resultDir%\%code%.csv"
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!diagnosisResult!","!status!","!action!" >> "%resultDir%\%code%.csv"

echo Audit complete. Results can be found in "%resultDir%\%code%.csv".
ENDLOCAL
pause
