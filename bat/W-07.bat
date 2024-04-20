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

:: 'EveryoneIncludesAnonymous' 정책 검사
set "진단결과=양호"
set "현황="

for /f "tokens=2 delims==" %%a in ('findstr /C:"EveryoneIncludesAnonymous =" "%rawPath%\Local_Security_Policy.txt"') do (
    set "everyoneIncludesAnonymous=%%a"
    if "!everyoneIncludesAnonymous!"=="0" (
        set "현황='모든 사용자가 익명 사용자를 포함' 정책이 '사용 안 함'으로 올바르게 설정되어 더 높은 보안을 보장합니다."
    ) else (
        set "진단결과=취약"
        set "현황='모든 사용자가 익명 사용자를 포함' 정책이 '사용 안 함'으로 설정되지 않아 잠재적 보안 위험을 초래합니다."
    )
)

:: 진단 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultPath%\W-07.csv"
echo 계정관리,W-07,상,Everyone 사용 권한을 익명 사용자에게 적용,!진단결과!,!현황!,Everyone 사용 권한을 익명 사용자에게 적용하지 않도록 설정 >> "%resultPath%\W-07.csv"

:: 스크립트 실행 완료 메시지
echo 스크립트 실행 완료
