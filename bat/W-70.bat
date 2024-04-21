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
set "코드=W-70"
set "위험도=높음"
set "진단_항목=이동식 미디어 포맷 및 추출 허용"
set "진단_결과=양호"
set "현황="
set "대응방안=이동식 미디어 포맷 및 추출에 대한 적절한 제어"

set "computerName=%COMPUTERNAME%"
set "resultDir=C:\Window_%computerName%_result"

:: Ensure the directory exists
if not exist "%resultDir%" mkdir "%resultDir%"

:: Perform security check (Simulating security check here)
:: You can replace this with actual commands to check system settings
set "policyEnabled=1"
if "!policyEnabled!"=="1" (
    set "진단_결과=양호"
    set "현황=디스크 할당 권한 변경은 관리자만 제한적으로 변경할 수 있습니다."
) else (
    set "진단_결과=취약"
    set "현황=디스크 할당 권한 변경이 관리자만으로 제한되지 않습니다."
)

:: Save results in CSV format
echo 분류,코드,위험도,진단_항목,진단_결과,현황,대응방안 > "%resultDir%\%코드%.csv"
echo %분류%,%코드%,%위험도%,%진단_항목%,%진단_결과%,%현황%,%대응방안% >> "%resultDir%\%코드%.csv"

echo 진단 결과가 %resultDir%\%코드%.csv 에 저장되었습니다.
ENDLOCAL
pause
