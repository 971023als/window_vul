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
set "코드=W-76"
set "위험도=상"
set "진단 항목=사용자별 홈 디렉터리 권한 설정"
set "진단 결과=양호"
set "현황=점검 중..."
set "대응방안=사용자별 홈 디렉터리 권한 설정"

:: Directory for results
set "computerName=%COMPUTERNAME%"
set "resultDir=C:\Window_%computerName%_result"
if not exist "%resultDir%" mkdir "%resultDir%"

:: Checking user directory permissions
echo 사용자 디렉토리 권한을 점검합니다...
for /D %%u in (C:\Users\*) do (
    set "userDir=%%u"
    set "permCheck="
    icacls "!userDir!" | find "Everyone:(F)" > nul && set "permCheck=취약"
    if not "!permCheck!"=="" (
        echo !userDir! has full control for Everyone >> "%resultDir%\%코드%.csv"
        set "진단 결과=취약"
    )
)

:: Prepare CSV output
echo 분류, 코드, 위험도, 진단 항목, 진단 결과, 현황, 대응방안 > "%resultDir%\%코드%.csv"
echo %분류%, %코드%, %위험도%, %진단 항목%, %진단 결과%, %현황%, %대응방안% >> "%resultDir%\%코드%.csv"

echo 진단 결과가 저장되었습니다: %resultDir%\%코드%.csv
echo 스크립트를 종료합니다.
pause
ENDLOCAL
