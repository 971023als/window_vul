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

:: 계정 잠금 기간 설정 검사
set "진단결과=양호"
set "현황="

for /f "tokens=2 delims==" %%a in ('findstr /C:"LockoutDuration =" "%rawPath%\Local_Security_Policy.txt"') do set "lockoutDuration=%%a"
for /f "tokens=2 delims==" %%b in ('findstr /C:"ResetLockoutCount =" "%rawPath%\Local_Security_Policy.txt"') do set "resetLockoutCount=%%b"

if %resetLockoutCount% gtr 59 (
    if %lockoutDuration% gtr 59 (
        set "현황=정책 충족: '잠금 지속 시간'과 '잠금 카운트 리셋 시간'이 설정 요구사항을 충족합니다."
    ) else (
        set "진단결과=취약"
        set "현황=정책 미충족: '잠금 지속 시간' 또는 '잠금 카운트 리셋 시간'이 설정 요구사항을 미충족합니다."
    )
) else (
    set "진단결과=취약"
    set "현황=정책 미충족: '잠금 지속 시간' 또는 '잠금 카운트 리셋 시간'이 설정 요구사항을 미충족합니다."
)

:: 진단 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultPath%\W-08.csv"
echo 계정관리,W-08,상,계정 잠금 기간 설정,!진단결과!,!현황!,계정 잠금 기간 설정 >> "%resultPath%\W-08.csv"

:: 스크립트 실행 완료 메시지
echo 스크립트 실행 완료
