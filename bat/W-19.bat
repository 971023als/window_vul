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

:: 공유 설정 분석
net share > "%rawPath%\shares.txt"
for /f "tokens=1,* delims= " %%a in ('type "%rawPath%\shares.txt" ^| findstr /V "C:$ D:$ IPC$ ADMIN$ print$"') do (
    cacls "%%b" > "%rawPath%\%%a-permissions.txt"
    for /f "delims=" %%c in ('type "%rawPath%\%%a-permissions.txt" ^| findstr /C:"Everyone"') do (
        set "everyoneAccess=%%c"
        echo "문제 발견: 공유 폴더 '%%a'에 Everyone 그룹이 접근 가능: !everyoneAccess!" >> "%resultPath%\W-19.csv"
        set "진단결과=취약"
    )
    if not defined everyoneAccess (
        echo "문제 없음: 공유 폴더 '%%a' 보안 설정이 적절함, Everyone 그룹의 접근 제한됨." >> "%resultPath%\W-19.csv"
        set "진단결과=양호"
    )
)

:: 진단 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultPath%\W-19.csv"
echo 서비스관리,W-19,상,공유 권한 및 사용자 그룹 설정,!진단결과!,!현황!,공유 권한 및 사용자 그룹 설정 조정 >> "%resultPath%\W-19.csv"

:: 스크립트 실행 완료 메시지
echo 스크립트 실행 완료
