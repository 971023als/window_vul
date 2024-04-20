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

:: 보안 정책 파일 내보내기 및 시스템 정보 수집
secedit /export /cfg "%rawPath%\Local_Security_Policy.txt"
systeminfo > "%rawPath%\systeminfo.txt"

:: 원격 데스크톱 사용자 그룹 설정 검사
net localgroup "Remote Desktop Users" > "%rawPath%\RemoteDesktopUsers.txt"
type "%rawPath%\RemoteDesktopUsers.txt" | find /i "account_name" > nul
if %errorlevel% == 0 (
    set "진단결과=취약"
    set "현황=무단 사용자가 'Remote Desktop Users' 그룹에 포함됨."
) else (
    set "진단결과=양호"
    set "현황='Remote Desktop Users' 그룹에 무단 사용자가 없음. 준수 상태가 확인됨."
)

:: 진단 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultPath%\W-18.csv"
echo 계정관리,W-18,상,원격터미널 접속 가능한 사용자 그룹 제한,!진단결과!,!현황!,원격터미널 접속 가능한 사용자 그룹 제한 >> "%resultPath%\W-18.csv"

:: 스크립트 실행 완료 메시지
echo 스크립트 실행 완료
