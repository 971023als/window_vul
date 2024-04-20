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

:: 패스워드 최소 길이 설정 검사
set "진단결과=양호"
set "현황="

for /f "tokens=2 delims==" %%a in ('findstr /C:"MinimumPasswordLength =" "%rawPath%\Local_Security_Policy.txt"') do (
    set "minPasswordLength=%%a"
    if !minPasswordLength! geq 8 (
        set "현황=패스워드 최소 암호 길이가 8자 이상으로 적절하게 설정되어 있습니다."
    ) else (
        set "진단결과=취약"
        set "현황=패스워드 최소 암호 길이가 8자 미만으로 설정되어 있습니다."
    )
)

:: 진단 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultPath%\W-10.csv"
echo 계정관리,W-10,상,패스워드 최소 암호 길이,!진단결과!,!현황!,패스워드 최소 암호 길이 설정 >> "%resultPath%\W-10.csv"

:: 스크립트 실행 완료 메시지
echo 스크립트 실행 완료
