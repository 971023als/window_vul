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
set "CODE=W-49"
set "RISK=상"
set "ITEM=원격 시스템에서 강제로 시스템 종료"
set "ACTION=로컬 보안 정책에서 해당 권한에 'Administrators' 외 다른 그룹 제거"
set "CSV_FILE=Remote_Shutdown_Right_Check.csv"

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
set "TEMP_CFG=%TEMP%\secpol_export.cfg"
set "PRIV_LINE="
set "SID_ADMIN=S-1-5-32-544"

:: 사용자 권한 정책 내보내기
secedit /export /cfg "%TEMP_CFG%" /areas USER_RIGHTS >nul 2>&1

:: SeRemoteShutdownPrivilege (원격 강제 종료 권한) 라인 추출
findstr /i "SeRemoteShutdownPrivilege" "%TEMP_CFG%" > "%TEMP%\priv_check.txt"
set /p PRIV_LINE=<"%TEMP%\priv_check.txt"

:: 임시 파일 정리
if exist "%TEMP_CFG%" del "%TEMP_CFG%"
if exist "%TEMP%\priv_check.txt" del "%TEMP%\priv_check.txt"

:: 4. 판정 로직
:: 양호 기준: Administrators(S-1-5-32-544)만 존재해야 함
:: 취약 기준: 콤마(,)가 있어서 여러 그룹이거나, Admin SID가 없거나, 다른 SID가 있는 경우

if "!PRIV_LINE!"=="" (
    :: 설정된 그룹이 아예 없는 경우 (보안상 안전하지만, 관리 목적상 Admin은 있는게 보통임)
    set "RESULT=양호"
    set "STATUS_MSG=원격 종료 권한이 아무에게도 할당되어 있지 않습니다."
) else (
    :: 1. 콤마(,)가 있는지 확인 (여러 그룹이 할당된 경우 취약)
    echo !PRIV_LINE! | findstr "," >nul
    if !errorlevel! equ 0 (
        set "RESULT=취약"
        set "STATUS_MSG=Administrators 외 불필요한 계정/그룹이 포함되어 있습니다. (!PRIV_LINE!)"
    ) else (
        :: 2. Administrators SID가 포함되어 있는지 확인
        echo !PRIV_LINE! | findstr "!SID_ADMIN!" >nul
        if !errorlevel! equ 0 (
            set "RESULT=양호"
            set "STATUS_MSG=Administrators 그룹만 권한을 가지고 있습니다."
        ) else (
            set "RESULT=취약"
            set "STATUS_MSG=Administrators 그룹이 아닌 다른 그룹만 권한을 가지고 있습니다. (!PRIV_LINE!)"
        )
    )
)

:: 5. 결과 출력 및 CSV 저장
echo [결과] : %RESULT%
echo [현황] : %STATUS_MSG%
echo ------------------------------------------------

:: CSV 저장 (메시지 내 콤마 및 등호 제거)
set "CLEAN_MSG=%STATUS_MSG:,= %"
set "CLEAN_MSG=%CLEAN_MSG:== %"
echo "%CATEGORY%","%CODE%","%RISK%","%ITEM%","%RESULT%","%CLEAN_MSG%","%ACTION%" >> "%FULL_PATH%"

echo.
echo 점검 완료! 결과가 저장되었습니다: %FULL_PATH%
pause