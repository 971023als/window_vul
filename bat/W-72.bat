@echo off
SETLOCAL EnableDelayedExpansion

:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    PowerShell -Command "Start-Process cmd.exe -ArgumentList '/c %~f0' -Verb RunAs"
    exit
)

:: Set environment
chcp 437 >nul
color 0A
cls
echo Setting up environment...

:: Variables
set "Category=보안 관리"
set "Code=W-72"
set "RiskLevel=높음"
set "DiagnosticItem=DOS 공격 방어 레지스트리 설정"
set "DiagnosticResult=양호"
set "Status=Checking DOS defense registry settings..."
set "Countermeasure=DOS 공격 방어를 위한 레지스트리 설정 조정"

:: Directory for results
set "computerName=%COMPUTERNAME%"
set "resultDir=C:\Windows_Security_Audit\%computerName%_results"
if not exist "%resultDir%" mkdir "%resultDir%"

:: Check registry for SynAttackProtect
for /f "tokens=3" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v SynAttackProtect 2^>nul') do set "SynAttackProtect=%%i"

:: Update diagnostic result based on registry value
if "!SynAttackProtect!"=="0x1" (
    set "Status=SynAttackProtect is enabled, enhancing DOS attack defense."
) else (
    set "DiagnosticResult=취약"
    set "Status=SynAttackProtect is disabled or not properly configured."
)

:: Prepare CSV output
echo 분류, 코드, 위험도, 진단 항목, 진단 결과, 현황, 대응방안 > "%resultDir%\%Code%.csv"
echo %Category%, %Code%, %RiskLevel%, %DiagnosticItem%, %DiagnosticResult%, %Status%, %Countermeasure% >> "%resultDir%\%Code%.csv"

echo 진단 결과가 저장되었습니다: %resultDir%\%Code%.csv
echo 스크립트를 종료합니다.
pause
ENDLOCAL
