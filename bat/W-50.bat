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
set "CODE=W-50"
set "RISK=상"
set "ITEM=보안 감사를 로그 할 수 없는 경우 즉시 시스템 종료"
set "ACTION=보안 옵션에서 '보안 감사를 로그 할 수 없는 경우 즉시 시스템 종료'를 '사용 안 함'으로 설정"
set "CSV_FILE=Audit_Fail_Shutdown_Check.csv"

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
:: 경로: HKLM\SYSTEM\CurrentControlSet\Control\Lsa
set "REG_PATH=HKLM\SYSTEM\CurrentControlSet\Control\Lsa"
set "CRASH_VAL="

for /f "tokens=3" %%A in ('reg query "%REG_PATH%" /v CrashOnAuditFail 2^>nul') do (
    set "CRASH_VAL=%%A"
)

:: 4. 판정 로직
:: 0: 사용 안 함 (양호)
:: 1: 사용 (취약 - 로그 가득 차면 관리자 외 로그인 불가)
:: 2: 사용 (취약 - 로그 가득 차면 시스템 종료/중지 오류)

if "!CRASH_VAL!"=="0x0" (
    set "RESULT=양호"
    set "STATUS_MSG=정책이 '사용 안 함(0)'으로 설정되어 있습니다."
) else if "!CRASH_VAL!"=="0x1" (
    set "RESULT=취약"
    set "STATUS_MSG=정책이 '사용(1)'으로 설정되어 있어 로그 만료 시 시스템 접근이 제한될 수 있습니다."
) else if "!CRASH_VAL!"=="0x2" (
    set "RESULT=취약"
    set "STATUS_MSG=정책이 '사용(2)'으로 설정되어 있어 로그 만료 시 시스템이 강제 종료됩니다."
) else (
    :: 값이 없는 경우 윈도우 기본값은 0(사용 안 함)이지만, 명시적 확인을 위해 양호 처리 및 메시지 출력
    set "RESULT=양호"
    set "STATUS_MSG=설정값이 존재하지 않습니다. (Windows 기본값: 사용 안 함)"
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