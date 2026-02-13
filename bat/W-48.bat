@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

:: 1. 관리자 권한 확인
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] 이 스크립트는 관리자 권한으로 실행해야 합니다.
    pause
    exit /b
)

:: 2. 진단 정보 및 파일 설정
set "CATEGORY=보안 관리"
set "CODE=W-48"
set "RISK=상"
set "ITEM=로그온하지 않고 시스템 종료 허용"
set "ACTION=보안 옵션에서 '시스템 종료: 로그온하지 않고 시스템 종료 허용'을 '사용 안 함'으로 설정"
set "CSV_FILE=Shutdown_Without_Logon_Check.csv"

:: 결과 폴더 생성
if not exist "result" mkdir "result"
set "FULL_PATH=result\%CSV_FILE%"

:: CSV 헤더 생성
if not exist "%FULL_PATH%" (
    echo Category,Code,Risk Level,Diagnosis Item,Result,Current Status,Remedial Action > "%FULL_PATH%"
)

echo ------------------------------------------------
echo CODE [%CODE%] %ITEM% 점검 시작
echo ------------------------------------------------

:: 3. 실제 점검 로직 (레지스트리 쿼리)
:: 경로: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
:: 키: shutdownwithoutlogon
set "REG_PATH=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
set "SHUTDOWN_VAL="

for /f "tokens=3" %%A in ('reg query "%REG_PATH%" /v shutdownwithoutlogon 2^>nul') do (
    set "SHUTDOWN_VAL=%%A"
)

:: 4. 판정 로직
:: 0x0 (0): 사용 안 함 (양호 - 버튼 숨김)
:: 0x1 (1): 사용 (취약 - 버튼 보임)

if "!SHUTDOWN_VAL!"=="0x0" (
    set "RESULT=양호"
    set "STATUS_MSG=정책이 '사용 안 함(0)'으로 설정되어 로그온 전 종료 버튼이 비활성화되었습니다."
) else if "!SHUTDOWN_VAL!"=="0x1" (
    set "RESULT=취약"
    set "STATUS_MSG=정책이 '사용(1)'으로 설정되어 로그온 없이 시스템 종료가 가능합니다."
) else (
    :: 값이 없는 경우 (서버 제품군 기본값은 0이나, 명시적 설정이 없으면 취약으로 간주하거나 경고)
    set "RESULT=취약"
    set "STATUS_MSG=해당 레지스트리 설정이 존재하지 않습니다. (명시적 설정 필요)"
)

:: 5. 결과 출력 및 CSV 저장
echo [결과] : %RESULT%
echo [현황] : %STATUS_MSG%
echo ------------------------------------------------

:: CSV 저장 (메시지 내 콤마 제거)
set "CLEAN_MSG=%STATUS_MSG:,= %"
echo "%CATEGORY%","%CODE%","%RISK%","%ITEM%","%RESULT%","%CLEAN_MSG%","%ACTION%" >> "%FULL_PATH%"

echo.
echo 점검 완료! 결과가 저장되었습니다: %FULL_PATH%
pause