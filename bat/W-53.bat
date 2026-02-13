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
set "CODE=W-53"
set "RISK=상"
set "ITEM=이동식 미디어 포맷 및 꺼내기 허용"
set "ACTION=보안 옵션에서 '장치: 이동식 미디어 포맷 및 꺼내기 허용'을 'Administrators'로 설정"
set "CSV_FILE=Removable_Media_Policy_Check.csv"

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
:: 경로: HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon
:: 값: AllocateDASD (0: Admin, 1: Admin/PowerUsers, 2: Admin/InteractiveUsers)
set "REG_PATH=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
set "DASD_VAL="

for /f "tokens=3" %%A in ('reg query "%REG_PATH%" /v AllocateDASD 2^>nul') do (
    set "DASD_VAL=%%A"
)

:: 4. 판정 로직
if "!DASD_VAL!"=="0x0" (
    set "RESULT=양호"
    set "STATUS_MSG=정책이 'Administrators(0)'로 설정되어 권한이 적절히 제한되어 있습니다."
) else (
    if "!DASD_VAL!"=="0x1" (
        set "RESULT=취약"
        set "STATUS_MSG=정책이 'Administrators 및 Power Users(1)'로 설정되어 권한이 과다합니다."
    ) else if "!DASD_VAL!"=="0x2" (
        set "RESULT=취약"
        set "STATUS_MSG=정책이 'Administrators 및 Interactive Users(2)'로 설정되어 권한이 과다합니다."
    ) else (
        :: 설정값이 아예 없는 경우 (기본값은 Admin이지만 명시적 보안 설정을 권장하므로 점검 필요)
        set "RESULT=취약"
        set "STATUS_MSG=해당 보안 정책이 레지스트리에 설정되어 있지 않습니다."
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