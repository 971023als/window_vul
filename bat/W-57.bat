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
set "CODE=W-57"
set "RISK=하"
set "ITEM=로그온 시 경고 메시지 설정"
set "ACTION=보안 옵션에서 '로그온 시도하는 사용자에 대한 메시지 제목/텍스트'를 설정"
set "CSV_FILE=Login_Banner_Check.csv"

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
:: 현대 Windows 표준 경로: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
set "REG_PATH=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
set "CAPTION_VAL="
set "TEXT_VAL="

:: 제목(Caption) 확인
for /f "tokens=2,*" %%A in ('reg query "%REG_PATH%" /v legalnoticecaption 2^>nul ^| findstr "REG_SZ"') do (
    set "CAPTION_VAL=%%B"
)

:: 내용(Text) 확인
for /f "tokens=2,*" %%A in ('reg query "%REG_PATH%" /v legalnoticetext 2^>nul ^| findstr "REG_SZ"') do (
    set "TEXT_VAL=%%B"
)

:: 4. 판정 로직
:: 제목과 내용이 모두 비어있지 않아야 양호
if "!CAPTION_VAL!"=="" (
    set "RESULT=취약"
    set "STATUS_MSG=로그온 경고 메시지 제목이 설정되어 있지 않습니다."
) else if "!TEXT_VAL!"=="" (
    set "RESULT=취약"
    set "STATUS_MSG=로그온 경고 메시지 내용이 설정되어 있지 않습니다."
) else (
    set "RESULT=양호"
    set "STATUS_MSG=경고 메시지가 설정되어 있습니다. (제목: !CAPTION_VAL!)"
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