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
echo 환경을 초기화 중입니다...

:: Define variables
set "Category=보안 관리"
set "Code=W-71"
set "RiskLevel=높음"
set "DiagnosticItem=디스크 볼륨 암호화 설정"
set "DiagnosticResult=양호"
set "Status=암호화 상태를 확인하는 중..."
set "Countermeasure=디스크 볼륨 암호화 설정을 통한 데이터 보호 강화"

:: Directory for storing the results
set "computerName=%COMPUTERNAME%"
set "resultDir=C:\Windows_Security_Audit\%computerName%_results"
if not exist "%resultDir%" mkdir "%resultDir%"

:: Check BitLocker status using PowerShell
for /f "tokens=*" %%i in ('PowerShell -Command "(Get-BitLockerVolume -MountPoint C:).ProtectionStatus"') do set "ProtectionStatus=%%i"

:: Update diagnostic result based on BitLocker status
if "%ProtectionStatus%"=="1" (
    set "Status=BitLocker로 C: 드라이브가 암호화되었습니다."
) else (
    set "DiagnosticResult=취약"
    set "Status=BitLocker로 C: 드라이브가 암호화되지 않았습니다."
)

:: Prepare CSV output
echo 분류, 코드, 위험도, 진단 항목, 진단 결과, 현황, 대응방안 > "%resultDir%\%Code%.csv"
echo %Category%, %Code%, %RiskLevel%, %DiagnosticItem%, %DiagnosticResult%, %Status%, %Countermeasure% >> "%resultDir%\%Code%.csv"

echo 진단 결과가 저장되었습니다: %resultDir%\%Code%.csv
echo 스크립트가 완료되었습니다.
pause
ENDLOCAL
