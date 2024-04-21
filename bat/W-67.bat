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
echo 설정을 초기화 중입니다...

:: Variables
set "분류=보안 관리"
set "코드=W-67"
set "위험도=높음"
set "진단항목=보안 감사를 기록할 수 없는 경우 시스템 즉시 종료"
set "진단결과=양호"
set "현황="
set "대응방안=보안 감사를 기록할 수 없는 경우 시스템을 종료하도록 정책을 적절하게 구성"

set "computerName=%COMPUTERNAME%"
set "resultDir=C:\Window_%computerName%_result"

:: Create and clean directories
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%resultDir%"

:: Check the policy for "Crash on Audit Fail"
for /f "tokens=2,*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v CrashOnAuditFail') do (
    set policy=%%b
)

:: Analyze and record results
if "!policy!"=="0x1" (
    set "진단결과=양호"
    set "현황=보안 감사를 기록할 수 없는 경우 시스템을 종료하도록 구성되어 보안이 강화되었습니다."
) else (
    set "진단결과=취약"
    set "현황=보안 감사를 기록할 수 없는 경우 시스템이 종료되지 않도록 구성되어 있어 보안 위험이 있을 수 있습니다."
)

:: Save results in CSV format with Korean labels
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\%코드%.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\%코드%.csv"

echo 감사가 완료되었습니다. 결과는 %resultDir%\%코드%.csv 파일에서 확인할 수 있습니다.
ENDLOCAL
pause
