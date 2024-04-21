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

:: Set up directory variables
set "분류=보안 관리"
set "코드=W-66"
set "위험도=높음"
set "진단항목=원격 시스템 강제 종료"
set "진단결과=양호"
set "현황="
set "대응방안=원격 시스템 종료를 허용하거나 거부할 수 있도록 정책을 적절하게 구성"

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
    set "진단결과=취약"
    set "현황=원격 시스템 종료 권한이 관리자 그룹에만 할당되어 있습니다."
) else (
    set "현황=원격 시스템 종료 권한이 안전하게 구성되어 있습니다."
)

:: Save results in CSV format
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\%코드%.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\%코드%.csv"

echo 감사가 완료되었습니다. 결과는 %resultDir%\%코드%.csv 파일에서 확인할 수 있습니다.
ENDLOCAL
pause
