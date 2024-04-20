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

:: 시스템 정보 수집
systeminfo > "%rawPath%\systeminfo.txt"

:: 로컬 보안 정책 내보내기
secedit /EXPORT /CFG "%rawPath%\Local_Security_Policy.txt"

:: 진단 시작
set "진단결과=양호"
set "현황="

:: 관리자 계정 이름 변경 확인
findstr "NewAdministratorName" "%rawPath%\Local_Security_Policy.txt" >nul || (
    set "진단결과=취약"
    set "현황=관리자 계정의 기본 이름이 변경되지 않았습니다."
)

:: 진단 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultPath%\W-01.csv"
echo 계정관리,W-01,상,Administrator 계정 이름 바꾸기,!진단결과!,!현황!,Administrator 계정 이름 변경 >> "%resultPath%\W-01.csv"

:: 스크립트 실행 완료 메시지
echo 스크립트 실행 완료
