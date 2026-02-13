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
set "CODE=W-60"
set "RISK=중"
set "ITEM=보안 채널 데이터 디지털 암호화 또는 서명"
set "ACTION=보안 채널 암호화 및 서명 관련 3개 정책을 모두 '사용'으로 설정"
set "CSV_FILE=Secure_Channel_Security_Check.csv"

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
:: 경로: HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters
set "REG_PATH=HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters"
set "VULN_COUNT=0"
set "STATUS_DETAILS="

:: 점검 항목 1: RequireSignOrSeal (항상 암호화 또는 서명)
reg query "%REG_PATH%" /v RequireSignOrSeal 2>nul | findstr "0x1" >nul
if %errorLevel% neq 0 (
    set /a VULN_COUNT+=1
    set "STATUS_DETAILS=!STATUS_DETAILS! [RequireSignOrSeal 미설정]"
)

:: 점검 항목 2: SealSecureChannel (가능한 경우 암호화)
reg query "%REG_PATH%" /v SealSecureChannel 2>nul | findstr "0x1" >nul
if %errorLevel% neq 0 (
    set /a VULN_COUNT+=1
    set "STATUS_DETAILS=!STATUS_DETAILS! [SealSecureChannel 미설정]"
)

:: 점검 항목 3: SignSecureChannel (가능한 경우 서명)
reg query "%REG_PATH%" /v SignSecureChannel 2>nul | findstr "0x1" >nul
if %errorLevel% neq 0 (
    set /a VULN_COUNT+=1
    set "STATUS_DETAILS=!STATUS_DETAILS! [SignSecureChannel 미설정]"
)

:: 4. 판정 로직
if %VULN_COUNT% gtr 0 (
    set "RESULT=취약"
    set "STATUS_MSG=보안 채널 정책 중 일부(!VULN_COUNT!개)가 사용 안 함으로 되어 있습니다.!STATUS_DETAILS!"
) else (
    set "RESULT=양호"
    set "STATUS_MSG=3가지 보안 채널 암호화 및 서명 정책이 모두 사용으로 설정되어 있습니다."
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