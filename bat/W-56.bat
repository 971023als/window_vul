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
set "CODE=W-56"
set "RISK=중"
set "ITEM=SMB 세션 중단 관리 설정"
set "ACTION=보안 옵션에서 '로그온 시간 만료 시 클라이언트 연결 끊기'를 사용으로, '유휴 시간'을 15분 이하로 설정"
set "CSV_FILE=SMB_Session_Management_Check.csv"

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
:: 경로: HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters
set "REG_PATH=HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"

set "FORCE_LOGOFF="
set "AUTO_DISCONNECT="
set "IS_VULN=FALSE"
set "STATUS_DETAILS="

:: 3-1. enableforcedlogoff (로그온 시간 만료 시 연결 끊기)
for /f "tokens=3" %%A in ('reg query "%REG_PATH%" /v enableforcedlogoff 2^>nul') do (
    set "FORCE_LOGOFF=%%A"
)

:: 3-2. autodisconnect (유휴 시간 설정)
for /f "tokens=3" %%A in ('reg query "%REG_PATH%" /v autodisconnect 2^>nul') do (
    set "AUTO_DISCONNECT=%%A"
)

:: 4. 판정 로직
:: 정책 1: enableforcedlogoff (0x1 이여야 함)
if "!FORCE_LOGOFF!"=="0x1" (
    set "P1=OK"
) else (
    set "IS_VULN=TRUE"
    set "STATUS_DETAILS=!STATUS_DETAILS! [로그온 만료 시 끊기 미설정]"
)

:: 정책 2: autodisconnect (15분 이하, 즉 0xf 이하여야 함)
:: 16진수를 10진수로 변환하여 비교
if not "!AUTO_DISCONNECT!"=="" (
    set /a "AD_DEC=!AUTO_DISCONNECT!"
    if !AD_DEC! leq 15 (
        set "P2=OK"
    ) else (
        set "IS_VULN=TRUE"
        set "STATUS_DETAILS=!STATUS_DETAILS! [유휴 시간 초과(!AD_DEC!분)]"
    )
) else (
    :: 기본값이 설정되어 있지 않은 경우 (기본값은 보통 15분이지만 명시적 설정 권장)
    set "IS_VULN=TRUE"
    set "STATUS_DETAILS=!STATUS_DETAILS! [유휴 시간 값 누락]"
)

:: 최종 결과 정리
if "!IS_VULN!"=="TRUE" (
    set "RESULT=취약"
    set "STATUS_MSG=설정이 기준에 미달합니다:!STATUS_DETAILS!"
) else (
    set "RESULT=양호"
    set "STATUS_MSG=로그온 만료 시 연결 끊기 사용 중 및 유휴 시간(!AD_DEC!분)이 적절합니다."
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