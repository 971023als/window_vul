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
set "CODE=W-63"
set "RISK=중"
set "ITEM=도메인 컨트롤러-사용자의 시간 동기화"
set "ACTION=보안 정책에서 '컴퓨터 시계 동기화 최대 허용 오차'를 5분 이하로 설정"
set "CSV_FILE=Kerberos_Time_Sync_Check.csv"

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

:: 3. 실제 점검 로직 (secedit 이용)
set "TMP_FILE=%TEMP%\secedit_export.txt"
set "SKEW_VAL="

:: 로컬 보안 정책 내보내기 (SECURITYPOLICY 영역)
secedit /export /cfg "%TMP_FILE%" /areas SECURITYPOLICY >nul 2>&1

:: MaxClockSkew 값 찾기 (단위: 분)
for /f "tokens=2 delims==" %%A in ('type "%TMP_FILE%" ^| findstr /i "MaxClockSkew"') do (
    set "RAW_VAL=%%A"
    :: 공백 제거
    set "SKEW_VAL=!RAW_VAL: =!"
)

:: 임시 파일 삭제
if exist "%TMP_FILE%" del "%TMP_FILE%"

:: 4. 판정 로직
if "!SKEW_VAL!"=="" (
    :: 정책이 명시되지 않은 경우 (보통 단독 서버는 5분이 기본값임)
    set "RESULT=양호"
    set "STATUS_MSG=Kerberos 정책이 설정되어 있지 않으나 기본값(5분)으로 동작 중입니다."
) else (
    if !SKEW_VAL! GTR 5 (
        set "RESULT=취약"
        set "STATUS_MSG=최대 허용 오차가 5분을 초과하여 설정되어 있습니다 (현재: !SKEW_VAL!분)"
    ) else (
        set "RESULT=양호"
        set "STATUS_MSG=최대 허용 오차가 권고 기준(!SKEW_VAL!분) 내에 있습니다."
    )
)

:: 5. 결과 출력 및 CSV 저장
echo [결과] : %RESULT%
echo [현황] : %STATUS_MSG%
echo ------------------------------------------------

echo "%CATEGORY%","%CODE%","%RISK%","%ITEM%","%RESULT%","%STATUS_MSG%","%ACTION%" >> "%FULL_PATH%"

echo.
echo 점검 완료! 결과가 저장되었습니다: %FULL_PATH%
pause