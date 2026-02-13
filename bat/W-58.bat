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
set "CODE=W-58"
set "RISK=중"
set "ITEM=사용자별 홈 디렉터리 권한 설정"
set "ACTION=개별 사용자 홈 디렉터리 보안 속성에서 'Everyone' 권한 제거"
set "CSV_FILE=User_Home_Dir_Check.csv"

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

:: 3. 홈 디렉터리 기본 경로 탐색
set "USER_BASE="
if exist "C:\Users" (
    set "USER_BASE=C:\Users"
) else if exist "C:\Documents and Settings" (
    set "USER_BASE=C:\Documents and Settings"
) else if exist "C:\WinNT\Profiles" (
    set "USER_BASE=C:\WinNT\Profiles"
)

if "%USER_BASE%"=="" (
    set "RESULT=오류"
    set "STATUS_MSG=홈 디렉터리 경로를 찾을 수 없습니다."
    goto :OUTPUT
)

:: 4. 실제 점검 로직
set "IS_VULN=FALSE"
set "VULN_LIST="
set "CHECKED_COUNT=0"

:: 제외할 폴더 목록 (공용, 기본 프로필 등)
set "EXCLUDE=All Users Default Default User Public desktop.ini"

for /f "delims=" %%D in ('dir /b /ad "%USER_BASE%"') do (
    set "SKIP=FALSE"
    for %%E in (%EXCLUDE%) do (
        if /i "%%D"=="%%E" set "SKIP=TRUE"
    )

    if "!SKIP!"=="FALSE" (
        set /a CHECKED_COUNT+=1
        :: icacls를 사용하여 Everyone(S-1-1-0) 또는 모든 사용자 권한 확인
        icacls "%USER_BASE%\%%D" | findstr /i "Everyone S-1-1-0 모든 사용자" >nul
        if !errorLevel! equ 0 (
            set "IS_VULN=TRUE"
            set "VULN_LIST=!VULN_LIST! [%%D]"
        )
    )
)

:: 5. 판정 로직
if "%CHECKED_COUNT%"=="0" (
    set "RESULT=양호"
    set "STATUS_MSG=점검할 일반 사용자 디렉터리가 존재하지 않습니다."
) else if "!IS_VULN!"=="TRUE" (
    set "RESULT=취약"
    set "STATUS_MSG=다음 사용자 폴더에 Everyone 권한이 있습니다:!VULN_LIST!"
) else (
    set "RESULT=양호"
    set "STATUS_MSG=모든 사용자 디렉터리(!CHECKED_COUNT!개)에 Everyone 권한이 제한되어 있습니다."
)

:OUTPUT
:: 6. 결과 출력 및 CSV 저장
echo [결과] : %RESULT%
echo [현황] : %STATUS_MSG%
echo ------------------------------------------------

:: CSV 저장 (메시지 내 콤마 제거)
set "CLEAN_MSG=%STATUS_MSG:,= %"
echo "%CATEGORY%","%CODE%","%RISK%","%ITEM%","%RESULT%","%CLEAN_MSG%","%ACTION%" >> "%FULL_PATH%"

echo.
echo 점검 완료! 결과가 저장되었습니다: %FULL_PATH%
pause