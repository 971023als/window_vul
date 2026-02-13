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
set "CODE=W-55"
set "RISK=중"
set "ITEM=사용자가 프린터 드라이버를 설치할 수 없게 함"
set "ACTION=보안 옵션에서 '장치: 사용자가 프린터 드라이버를 설치할 수 없게 함'을 '사용'으로 설정"
set "CSV_FILE=Printer_Driver_Install_Check.csv"

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
:: 경로: HKLM\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers
set "REG_PATH=HKLM\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers"
set "PRINTER_VAL="

for /f "tokens=3" %%A in ('reg query "%REG_PATH%" /v AddPrinterDrivers 2^>nul') do (
    set "PRINTER_VAL=%%A"
)

:: 4. 판정 로직
:: 0x1 (1): 사용 (양호 - 관리자만 설치 가능)
:: 0x0 (0): 사용 안 함 (취약 - 일반 사용자도 설치 가능)

if "!PRINTER_VAL!"=="0x1" (
    set "RESULT=양호"
    set "STATUS_MSG=정책이 '사용(1)'으로 설정되어 관리자만 드라이버를 설치할 수 있습니다."
) else if "!PRINTER_VAL!"=="0x0" (
    set "RESULT=취약"
    set "STATUS_MSG=정책이 '사용 안 함(0)'으로 설정되어 일반 사용자의 드라이버 설치가 가능합니다."
) else (
    :: 값이 존재하지 않는 경우 (기본적으로 보안을 위해 명시적 설정을 권장하므로 취약 처리)
    set "RESULT=취약"
    set "STATUS_MSG=해당 레지스트리 설정이 누락되어 있습니다. (기본 보안 정책 미확인)"
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