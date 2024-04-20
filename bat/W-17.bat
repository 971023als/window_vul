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

:: 'LimitBlankPasswordUse' 정책 설정 검사
set "진단결과=양호"
set "현황="

for /f "tokens=2 delims== eol= " %%a in ('findstr /R "LimitBlankPasswordUse = [0-9]*" "%rawPath%\Local_Security_Policy.txt"') do (
    set "limitBlankPasswordUse=%%a"
    if "!limitBlankPasswordUse!"=="1" (
        set "현황=준수 확인됨: 'LimitBlankPasswordUse' 정책이 올바르게 적용됨."
    ) else (
        set "진단결과=취약"
        set "현황=준수하지 않음 감지됨: 'LimitBlankPasswordUse' 정책이 올바르게 적용되지 않음."
    )
)

:: 진단 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultPath%\W-17.csv"
echo 계정관리,W-17,상,콘솔 로그온 시 로컬 계정에서 빈 암호 사용 제한,!진단결과!,!현황!,콘솔 로그온 시 로컬 계정에서 빈 암호 사용 제한 >> "%resultPath%\W-17.csv"

:: 스크립트 실행 완료 메시지
echo 스크립트 실행 완료
