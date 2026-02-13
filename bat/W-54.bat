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
set "CODE=W-54"
set "RISK=중"
set "ITEM=DoS 공격 방어 레지스트리 설정"
set "ACTION=Tcpip\Parameters 경로에 SynAttackProtect 등 4개 항목 권고치 적용"
set "CSV_FILE=DoS_Defense_Registry_Check.csv"

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
set "REG_PATH=HKLM\System\CurrentControlSet\Services\Tcpip\Parameters"
set "IS_VULN=FALSE"
set "STATUS_DETAILS="

:: --- 3-1. SynAttackProtect 점검 (1 이상 권고) ---
set "SYN_VAL="
for /f "tokens=3" %%A in ('reg query "%REG_PATH%" /v SynAttackProtect 2^>nul') do set "SYN_VAL=%%A"
if defined SYN_VAL (
    set /a "SYN_DEC=!SYN_VAL!"
    if !SYN_DEC! LSS 1 (
        set "IS_VULN=TRUE"
        set "STATUS_DETAILS=!STATUS_DETAILS! [SynAttackProtect 미흡(!SYN_DEC!)]"
    )
) else (
    set "IS_VULN=TRUE"
    set "STATUS_DETAILS=!STATUS_DETAILS! [SynAttackProtect 누락]"
)

:: --- 3-2. EnableDeadGWDetect 점검 (0 권고) ---
set "DGW_VAL="
for /f "tokens=3" %%A in ('reg query "%REG_PATH%" /v EnableDeadGWDetect 2^>nul') do set "DGW_VAL=%%A"
if defined DGW_VAL (
    set /a "DGW_DEC=!DGW_VAL!"
    if !DGW_DEC! NEQ 0 (
        set "IS_VULN=TRUE"
        set "STATUS_DETAILS=!STATUS_DETAILS! [EnableDeadGWDetect 미흡(!DGW_DEC!)]"
    )
) else (
    set "IS_VULN=TRUE"
    set "STATUS_DETAILS=!STATUS_DETAILS! [EnableDeadGWDetect 누락]"
)

:: --- 3-3. KeepAliveTime 점검 (300,000 권고) ---
set "KAT_VAL="
for /f "tokens=3" %%A in ('reg query "%REG_PATH%" /v KeepAliveTime 2^>nul') do set "KAT_VAL=%%A"
if defined KAT_VAL (
    set /a "KAT_DEC=!KAT_VAL!"
    if !KAT_DEC! NEQ 300000 (
        set "IS_VULN=TRUE"
        set "STATUS_DETAILS=!STATUS_DETAILS! [KeepAliveTime 미흡(!KAT_DEC!)]"
    )
) else (
    set "IS_VULN=TRUE"
    set "STATUS_DETAILS=!STATUS_DETAILS! [KeepAliveTime 누락]"
)

:: --- 3-4. NoNameReleaseOnDemand 점검 (1 권고) ---
set "NRD_VAL="
for /f "tokens=3" %%A in ('reg query "%REG_PATH%" /v NoNameReleaseOnDemand 2^>nul') do set "NRD_VAL=%%A"
if defined NRD_VAL (
    set /a "NRD_DEC=!NRD_VAL!"
    if !NRD_DEC! NEQ 1 (
        set "IS_VULN=TRUE"
        set "STATUS_DETAILS=!STATUS_DETAILS! [NoNameReleaseOnDemand 미흡(!NRD_DEC!)]"
    )
) else (
    set "IS_VULN=TRUE"
    set "STATUS_DETAILS=!STATUS_DETAILS! [NoNameReleaseOnDemand 누락]"
)

:: 4. 판정 로직
if "!IS_VULN!"=="TRUE" (
    set "RESULT=취약"
    set "STATUS_MSG=권고치와 다른 설정이 발견되었습니다:!STATUS_DETAILS!"
) else (
    set "RESULT=양호"
    set "STATUS_MSG=모든 DoS 방어 레지스트리가 권고치대로 설정되어 있습니다."
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