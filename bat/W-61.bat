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
set "CODE=W-61"
set "RISK=중"
set "ITEM=NTFS 파일 시스템 사용 여부 점검"
set "ACTION=FAT 계열 파일 시스템을 NTFS로 변환 (명령어: convert 드라이브: /fs:ntfs)"
set "CSV_FILE=File_System_Security_Check.csv"

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

:: 3. 실제 점검 로직 (WMIC 이용)
set "IS_VULN=FALSE"
set "DRIVE_INFO="
set "VULN_DRIVES="

:: 로컬 하드 디스크(DriveType=3)의 ID와 파일 시스템 추출
for /f "tokens=2 delims==" %%A in ('wmic logicaldisk where "drivetype=3" get DeviceID^,FileSystem /value 2^>nul') do (
    set "VAL=%%A"
    :: 값에서 불필요한 공백 제거
    set "VAL=!VAL:~0,-1!"
    
    :: 드라이브 문자인지 파일 시스템인지 구분하여 저장
    echo !VAL! | findstr /i ":" >nul
    if !errorLevel! equ 0 (
        set "CURRENT_DRIVE=!VAL!"
    ) else (
        set "CURRENT_FS=!VAL!"
        set "DRIVE_INFO=!DRIVE_INFO! [!CURRENT_DRIVE! !CURRENT_FS!]"
        
        :: NTFS 또는 ReFS가 아닌 경우 취약으로 간주
        echo !CURRENT_FS! | findstr /i /v "NTFS ReFS" >nul
        if !errorLevel! equ 0 (
            set "IS_VULN=TRUE"
            set "VULN_DRIVES=!VULN_DRIVES! !CURRENT_DRIVE!(!CURRENT_FS!)"
        )
    )
)

:: 4. 판정 로직
if "!IS_VULN!"=="TRUE" (
    set "RESULT=취약"
    set "STATUS_MSG=보안에 취약한 파일 시스템이 존재합니다:!VULN_DRIVES!"
) else (
    set "RESULT=양호"
    set "STATUS_MSG=모든 로컬 드라이브가 NTFS 또는 ReFS를 사용 중입니다.!DRIVE_INFO!"
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