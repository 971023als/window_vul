@echo off
SETLOCAL EnableDelayedExpansion

:: 관리자 권한으로 실행 확인
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process cmd -ArgumentList '/c %~0' -Verb RunAs"
    exit
)

:: 기본 설정
set "computerName=%COMPUTERNAME%"
set "rawPath=C:\Window_%computerName%_raw"
set "resultPath=C:\Window_%computerName%_result"

:: 디렉토리 초기화 및 생성
if exist "%rawPath%" rmdir /s /q "%rawPath%"
if exist "%resultPath%" rmdir /s /q "%resultPath%"
mkdir "%rawPath%"
mkdir "%resultPath%"

:: 보안 정책 파일 내보내기 및 시스템 정보 수집
secedit /export /cfg "%rawPath%\Local_Security_Policy.txt"
systeminfo > "%rawPath%\systeminfo.txt"

:: 특정 서비스의 실행 상태 확인
set "servicesToCheck=Alerter ClipBook Messenger 'Simple TCP/IP Services'"
for %%s in (%servicesToCheck%) do (
    sc query %%s | findstr /I "STATE" > nul
    if errorlevel 1 (
        echo %%s,Not Installed,Not Applicable >> "%resultPath%\W-21.csv"
    ) else (
        for /f "tokens=3" %%t in ('sc query %%s ^| findstr /I "STATE"') do (
            set state=%%t
            if "!state!"=="4  RUNNING" (
                echo %%s,Installed,Running >> "%resultPath%\W-21.csv"
            ) else (
                echo %%s,Installed,Not Running >> "%resultPath%\W-21.csv"
            )
        )
    )
)

:: 진단 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultPath%\W-21.csv"
echo 서비스관리,W-21,상,불필요한 서비스 제거,Status Report,상태 보고,불필요한 서비스 제거 조치 >> "%resultPath%\W-21.csv"

:: 스크립트 실행 완료 메시지
echo 스크립트 실행 완료
