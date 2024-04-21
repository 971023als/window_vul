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
echo 환경을 설정하고 있습니다...

:: Set up directory variables
set "분류=보안관리"
set "코드=W-65"
set "위험도=상"
set "진단항목=로그온 없이 종료 허용"
set "진단결과=양호"
set "현황="
set "대응방안=로그온 없이 종료 정책 조정"

set "computerName=%COMPUTERNAME%"
set "resultDir=C:\Window_%computerName%_result"

:: Create and clean directories
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%resultDir%"

:: Check the policy for "Shutdown without logon"
for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ShutdownWithoutLogon') do set shutdownWithoutLogon=%%a

if "!shutdownWithoutLogon!"=="0x0" (
    set "진단결과=취약"
    set "현황=로그온 없이 시스템 종료가 허용되지 않습니다."
) else (
    set "현황=로그온 없이 시스템 종료가 허용됩니다."
)

:: Save results in CSV format
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\%코드%.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\%코드%.csv"

echo 감사가 완료되었습니다. 결과는 %resultDir%\%코드%.csv에서 확인하세요.
ENDLOCAL
pause
