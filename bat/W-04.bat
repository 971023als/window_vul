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

:: 계정 잠금 임계값 검사
set "lockoutThreshold=0"
for /f "tokens=2 delims==" %%a in ('findstr /C:"LockoutBadCount =" "%rawPath%\Local_Security_Policy.txt"') do set "lockoutThreshold=%%a"

:: 진단 결과 설정
set "진단결과=양호"
set "현황="

if %lockoutThreshold% gtr 5 (
    set "진단결과=취약"
    set "현황=계정 잠금 임계값이 5회 시도보다 많게 설정되어 있습니다."
) else if %lockoutThreshold% equ 0 (
    set "진단결과=취약"
    set "현황=계정 잠금 임계값이 설정되지 않았습니다(없음)."
) else (
    set "현황=계정 잠금 임계값이 준수 범위 내에 설정되었습니다."
)

:: 진단 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultPath%\W-04.csv"
echo 계정관리,W-04,상,계정 잠금 임계값 설정,!진단결과!,!현황!,계정 잠금 임계값 설정 >> "%resultPath%\W-04.csv"

:: 스크립트 실행 완료 메시지
echo 스크립트 실행 완료
