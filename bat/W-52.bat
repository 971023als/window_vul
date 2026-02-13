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
set "CODE=W-52"
set "RISK=상"
set "ITEM=Autologon 기능 제어"
set "ACTION=AutoAdminLogon 레지스트리 값을 0으로 설정하고 DefaultPassword 존재 시 제거"
set "CSV_FILE=Autologon_Control_Check.csv"

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
set "REG_PATH=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
set "AUTO_LOGON="
set "DEF_PASS="

:: AutoAdminLogon 값 확인
for /f "tokens=3" %%A in ('reg query "%REG_PATH%" /v AutoAdminLogon 2^>nul') do (
    set "AUTO_LOGON=%%A"
)

:: DefaultPassword 존재 여부 확인 (비밀번호 노출 위험 체크)
reg query "%REG_PATH%" /v DefaultPassword >nul 2>&1
if %errorLevel% equ 0 set "DEF_PASS=EXIST"

:: 4. 판정 로직
if "!AUTO_LOGON!"=="1" (
    set "RESULT=취약"
    set "STATUS_MSG=자동 로그온 기능이 활성화(1)되어 있습니다."
    if "!DEF_PASS!"=="EXIST" (
        set "STATUS_MSG=!STATUS_MSG! 레지스트리에 비밀번호 정보가 노출되어 있습니다."
    )
) else (
    set "RESULT=양호"
    if "!AUTO_LOGON!"=="0" (
        set "STATUS_MSG=자동 로그온 기능이 비활성화(0)되어 있습니다."
    ) else (
        set "STATUS_MSG=자동 로그온 설정이 존재하지 않습니다. (기본값 비활성)"
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