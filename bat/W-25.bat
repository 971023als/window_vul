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

:: 암호 저장 정책 검사
:: 예시로, 특정 서비스의 설정을 확인
sc query "YourService" | find "RUNNING" >nul
if %errorlevel% == 0 (
    set "serviceStatus=Running"
    set "diagnosisResult=취약"
    set "status=암호화 설정이 활성화되어 있으나, 보안 문제가 있습니다."
) else (
    set "serviceStatus=Stopped"
    set "diagnosisResult=양호"
    set "status=암호화 설정이 비활성화되어 있어 안전합니다."
)

:: 진단 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultPath%\W-25.csv"
echo 서비스관리,W-25,상,암호를 저장하기 위한 복호화 가능한 암호화 사용,!diagnosisResult!,!status!,암호 저장을 위한 복호화 불가능한 암호화 사용 >> "%resultPath%\W-25.csv"

:: 스크립트 실행 완료 메시지
echo 스크립트 실행 완료
