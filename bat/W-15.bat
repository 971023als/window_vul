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

:: 익명 SID/이름 변환 정책 설정 검사
set "진단결과=양호"
set "현황="

for /f "tokens=2 delims== eol= " %%a in ('findstr /R "LSAAnonymousNameLookup = [0-9]*" "%rawPath%\Local_Security_Policy.txt"') do (
    set "LSAAnonymousNameLookup=%%a"
    if "!LSAAnonymousNameLookup!"=="0" (
        set "현황=준수 상태 감지됨: LSA 익명 이름 조회가 올바르게 비활성화되어 있습니다."
    ) else (
        set "진단결과=취약"
        set "현황=비준수 상태 감지됨: LSA 익명 이름 조회가 활성화되어 있습니다."
    )
)

:: 진단 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultPath%\W-15.csv"
echo 계정관리,W-15,상,익명 SID/이름 변환 허용,!진단결과!,!현황!,익명 SID/이름 변환 허용 >> "%resultPath%\W-15.csv"

:: 스크립트 실행 완료 메시지
echo 스크립트 실행 완료
