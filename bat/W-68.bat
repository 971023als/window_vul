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
echo 환경을 초기화 중입니다...

:: Define variables for CSV output
set "분류=보안 관리"
set "코드=W-68"
set "위험도=높음"
set "진단항목=SAM 계정 및 공유의 익명 열거 허용 안 함"
set "진단결과=양호"
set "현황="
set "대응방안=시스템 정책을 구성하여 익명 열거를 허용하지 않도록 설정"

set "computerName=%COMPUTERNAME%"
set "resultDir=C:\Windows_Security_Audit\%computerName%_result"

:: Create and clean directories
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%resultDir%"

:: Check the system policy regarding anonymous enumeration
for /f "tokens=2,*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\LSA" /v restrictanonymous') do set "restrictanonymous=%%b"
for /f "tokens=2,*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\LSA" /v RestrictAnonymousSAM') do set "RestrictAnonymousSAM=%%b"

:: Analyze and record results
if "!restrictanonymous!"=="1" and "!RestrictAnonymousSAM!"=="1" (
    set "현황=시스템이 SAM 계정 및 공유의 익명 열거를 제한하는 데 적절하게 구성되었습니다."
) else (
    set "진단결과=취약"
    set "현황=시스템이 SAM 계정 및 공유의 익명 열거를 제한하는 데 적절하게 구성되지 않았습니다."
)

:: Save results in CSV format
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\%코드%.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\%코드%.csv"

echo 진단 결과가 %resultDir%\%코드%.csv 에 저장되었습니다.
ENDLOCAL
pause
