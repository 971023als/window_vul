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

:: 관리자 그룹 멤버 검사
net localgroup Administrators > "%rawPath%\administrators.txt"

:: 진단 시작
set "진단결과=양호"
set "현황="

:: 관리자 그룹 내 비허용 사용자 확인
for /f "tokens=*" %%i in ('type "%rawPath%\administrators.txt" ^| findstr /C:"test" /C:"Guest"') do (
    set "진단결과=취약"
    set "현황=!현황!관리자 그룹에 임시 또는 게스트 계정('test', 'Guest')이 포함되어 있습니다; "
)

if "!진단결과!"=="양호" (
    set "현황=관리자 그룹에 임시 또는 게스트 계정이 포함되지 않아 보안 정책을 준수합니다."
)

:: 진단 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultPath%\W-06.csv"
echo 계정관리,W-06,상,관리자 그룹에 최소한의 사용자 포함,!진단결과!,!현황!,관리자 그룹에 최소한의 사용자 포함 >> "%resultPath%\W-06.csv"

:: 스크립트 실행 완료 메시지
echo 스크립트 실행 완료
