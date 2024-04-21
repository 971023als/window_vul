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
set "코드=W-64"
set "위험도=상"
set "진단항목=화면보호기설정"
set "진단결과=양호"
set "현황="
set "대응방안=화면보호기설정 조정"

set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Windows_Security_Audit\%computerName%_raw"
set "resultDir=C:\Windows_Security_Audit\%computerName%_result"

:: Create and clean directories
if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: Check screen saver settings
for /f "tokens=2 delims==" %%a in ('reg query "HKCU\Control Panel\Desktop" /v ScreenSaveActive') do set ScreenSaveActive=%%a
for /f "tokens=2 delims==" %%b in ('reg query "HKCU\Control Panel\Desktop" /v ScreenSaverIsSecure') do set ScreenSaverIsSecure=%%b
for /f "tokens=2 delims==" %%c in ('reg query "HKCU\Control Panel\Desktop" /v ScreenSaveTimeOut') do set ScreenSaveTimeOut=%%c

if "!ScreenSaveActive!"=="1" (
    if "!ScreenSaverIsSecure!"=="1" (
        if !ScreenSaveTimeOut! lss 600 (
            set "진단결과=취약"
            set "현황=스크린 세이버가 활성화되었으나, 타임아웃 시간이 10분 미만으로 설정되어 있습니다."
        ) else (
            set "현황=스크린 세이버가 적절히 설정되어 있습니다."
        )
    ) else (
        set "진단결과=취약"
        set "현황=안전한 로그온이 요구되지 않는 스크린 세이버가 설정되어 있습니다."
    )
) else (
    set "진단결과=취약"
    set "현황=스크린 세이버가 비활성화되어 있습니다."
)

:: Save results in CSV format
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\%코드%.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\%코드%.csv"

echo 감사가 완료되었습니다. 결과는 %resultDir%\%코드%.csv에서 확인하세요.
ENDLOCAL
pause
