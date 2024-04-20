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

:: 보안 정책 파일 내보내기
secedit /export /cfg "%rawPath%\Local_Security_Policy.txt"

:: 패스워드 최소 사용 기간 설정 검사
set "진단결과=양호"
set "현황="

for /f "tokens=2 delims== eol= " %%a in ('findstr /R "MinimumPasswordAge = [0-9]*" "%rawPath%\Local_Security_Policy.txt"') do (
    set "minimumPasswordAge=%%a"
    if !minimumPasswordAge! gtr 0 (
        set "현황=최소 암호 사용 기간은 설정됨: !minimumPasswordAge!일."
    ) else (
        set "진단결과=취약"
        set "현황=최소 암호 사용 기간이 설정되지 않음."
    )
)

:: 진단 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultPath%\W-12.csv"
echo 계정관리,W-12,상,패스워드최소사용기간,!진단결과!,!현황!,패스워드최소사용기간 설정 >> "%resultPath%\W-12.csv"

:: 스크립트 실행 완료 메시지
echo 스크립트 실행 완료
