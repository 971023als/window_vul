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

:: 사용자 계정 정보 수집
net user > "%rawPath%\users.txt"

:: 진단 시작
set "진단결과=양호"
set "현황="

:: 사용자 계정 상태 분석
for /f "skip=4 delims=" %%i in ('type "%rawPath%\users.txt"') do (
    set "line=%%i"
    for %%u in (!line!) do (
        net user %%u > "%rawPath%\user_%%u.txt"
        findstr /C:"Account active               Yes" "%rawPath%\user_%%u.txt" >nul && (
            set "진단결과=취약"
            set "현황=!현황!활성화된 계정: %%u; "
        )
    )
)

:: 진단 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultPath%\W-03.csv"
echo 계정관리,W-03,상,불필요한 계정 제거,!진단결과!,!현황!,불필요한 계정 제거 >> "%resultPath%\W-03.csv"

:: 스크립트 실행 완료 메시지
echo 스크립트 실행 완료
