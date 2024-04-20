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

:: 로컬 보안 정책 내보내기
secedit /EXPORT /CFG "%rawPath%\Local_Security_Policy.txt"

:: 게스트 계정 정보 확인
net user guest > "%rawPath%\guest_info.txt"

:: 진단 시작
set "진단결과=양호"
set "현황="

:: 게스트 계정 활성화 여부 확인
findstr /C:"Account active               Yes" "%rawPath%\guest_info.txt" >nul && (
    set "진단결과=취약"
    set "현황=게스트 계정이 활성화 되어 있는 위험 상태로, 조치가 필요합니다."
) || (
    set "현황=게스트 계정이 비활성화 상태로 유지되고 있으므로 안전합니다."
)

:: 진단 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultPath%\W-02.csv"
echo 계정관리,W-02,상,Guest 계정 상태,!진단결과!,!현황!,Guest 계정 상태 변경 >> "%resultPath%\W-02.csv"

:: 스크립트 실행 완료 메시지
echo 스크립트 실행 완료
