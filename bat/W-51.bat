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
set "CODE=W-51"
set "RISK=상"
set "ITEM=SAM 계정과 공유의 익명 열거 허용 안 함"
set "ACTION=보안 옵션에서 '네트워크 액세스: SAM 계정과 공유의 익명 열거 허용 안 함'을 '사용'으로 설정"
set "CSV_FILE=Anonymous_Enumeration_Check.csv"

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
set "RESTRICT_SAM="
set "RESTRICT_ANON="

:: 3-1. RestrictAnonymousSAM (SAM 계정 익명 열거 제한)
for /f "tokens=3" %%A in ('reg query "%REG_PATH%" /v RestrictAnonymousSAM 2^>nul') do (
    set "RESTRICT_SAM=%%A"
)

:: 3-2. RestrictAnonymous (일반 익명 연결 제한)
for /f "tokens=3" %%A in ('reg query "%REG_PATH%" /v RestrictAnonymous 2^>nul') do (
    set "RESTRICT_ANON=%%A"
)

:: 4. 판정 로직
:: RestrictAnonymousSAM 값이 1(사용)이어야 양호
if "!RESTRICT_SAM!"=="0x1" (
    set "RESULT=양호"
    set "STATUS_MSG=정책이 '사용(1)'으로 설정되어 익명 열거가 제한되어 있습니다."
) else (
    set "RESULT=취약"
    if "!RESTRICT_SAM!"=="0x0" (
        set "STATUS_MSG=정책이 '사용 안 함(0)'으로 설정되어 익명 사용자의 계정 조회가 가능합니다."
    ) else (
        set "STATUS_MSG=해당 레지스트리 설정이 누락되어 있습니다."
    )
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