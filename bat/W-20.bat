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

:: 공유 관련 정책 설정 검사
net share > "%rawPath%\shares.txt"
set "진단결과=양호"
set "현황=기본 공유가 제거됨"

:: 검사 공유 목록에서 기본 공유 (C$, ADMIN$, IPC$) 확인
for /f "tokens=1,* delims= " %%a in ('type "%rawPath%\shares.txt" ^| findstr /C:"C$" /C:"ADMIN$" /C:"IPC$"') do (
    set "진단결과=취약"
    set "현황=기본 공유 %%a가 존재함"
)

:: 진단 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultPath%\W-20.csv"
echo 서비스관리,W-20,상,하드디스크 기본 공유 제거,!진단결과!,!현황!,하드디스크 기본 공유 제거 >> "%resultPath%\W-20.csv"

:: 스크립트 실행 완료 메시지
echo 스크립트 실행 완료
