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

:: 보안 정책 내보내기
secedit /export /cfg "%rawPath%\Local_Security_Policy.txt"

:: 가역 암호화 정책 검사
set "진단결과=양호"
set "현황="

for /f "tokens=2 delims==" %%a in ('findstr /C:"ClearTextPassword =" "%rawPath%\Local_Security_Policy.txt"') do (
    set "clearTextPassword=%%a"
    if "!clearTextPassword!"=="0" (
        set "현황=가역 암호화를 사용하여 비밀번호 저장 정책이 '사용 안 함'으로 설정되어 있습니다."
    ) else (
        set "진단결과=취약"
        set "현황=가역 암호화를 사용하여 비밀번호 저장 정책이 적절히 구성되지 않았습니다."
    )
)

:: 진단 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultPath%\W-05.csv"
echo 계정관리,W-05,상,해독 가능한 암호화를 사용하여 암호 저장,!진단결과!,!현황!,해독 가능한 암호화를 사용하여 암호 저장 방지 >> "%resultPath%\W-05.csv"

:: 스크립트 실행 완료 메시지
echo 스크립트 실행 완료
