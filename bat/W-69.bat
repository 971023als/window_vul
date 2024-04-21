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
echo 환경을 초기화 중입니다...

:: Define variables
set "분류=보안 관리"
set "코드=W-69"
set "위험도=높음"
set "진단_항목=자동 로그온 기능 제어"
set "진단_결과=양호"
set "현황="
set "대응방안=보안 강화를 위해 자동 로그온 기능을 비활성화"

set "computerName=%COMPUTERNAME%"
set "resultDir=C:\Window_%computerName%_result"

:: Ensure the directory exists
if not exist "%resultDir%" mkdir "%resultDir%"

:: Perform security check (Simulating security check here)
:: You can replace this with actual commands to check system settings
set "autoLogonEnabled=0"
if "!autoLogonEnabled!"=="1" (
    set "진단_결과=취약"
    set "현황=AutoAdminLogon이 활성화되어 보안 위험을 초래합니다."
) else (
    set "현황=AutoAdminLogon이 비활성화되어 시스템 보안이 강화되었습니다."
)

:: Save results in CSV format
echo 분류,코드,위험도,진단_항목,진단_결과,현황,대응방안 > "%resultDir%\%코드%.csv"
echo %분류%,%코드%,%위험도%,%진단_항목%,%진단_결과%,%현황%,%대응방안% >> "%resultDir%\%코드%.csv"

echo 진단 결과가 %resultDir%\%코드%.csv 에 저장되었습니다.
ENDLOCAL
pause
