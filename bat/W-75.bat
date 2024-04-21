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
echo 환경을 설정하는 중...

:: Variables
set "분류=보안 관리"
set "코드=W-75"
set "위험도=높음"
set "진단 항목=로그인 경고 메시지 설정"
set "진단 결과=양호"
set "현황=점검 중..."
set "대응방안=로그인 경고 메시지 설정 조정"

:: Directory for results
set "computerName=%COMPUTERNAME%"
set "resultDir=C:\Window_%computerName%_result"
if not exist "%resultDir%" mkdir "%resultDir%"

:: Simulate checking the policy
:: Here, we'll need actual commands to check the policy in real scenarios
set "policyEnabled=1"

:: Update diagnostic result based on the policy value
if "%policyEnabled%"=="1" (
    set "진단 결과=취약"
    set "현황=로그인 경고 메시지가 설정되어 있습니다."
) else (
    set "현황=로그인 경고 메시지가 설정되어 있지 않습니다."
)

:: Prepare CSV output
echo 분류, 코드, 위험도, 진단 항목, 진단 결과, 현황, 대응방안 > "%resultDir%\%코드%.csv"
echo %분류%, %코드%, %위험도%, %진단 항목%, %진단 결과%, %현황%, %대응방안% >> "%resultDir%\%코드%.csv"

echo 진단 결과가 저장되었습니다: %resultDir%\%코드%.csv
echo 스크립트를 종료합니다.
pause
ENDLOCAL
