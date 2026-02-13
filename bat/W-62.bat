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
set "CODE=W-62"
set "RISK=중"
set "ITEM=시작 프로그램 목록 분석"
set "ACTION=불필요하거나 의심스러운 시작 프로그램 삭제 및 비활성화 (Taskmgr 또는 레지스트리 정리)"
set "CSV_FILE=Startup_Program_Analysis.csv"

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

:: 3. 실제 점검 로직
set "STARTUP_LIST="
set "COUNT=0"

:: 레지스트리 주요 시작 프로그램 경로 조사 (HKLM 및 HKCU)
set "REG_PATHS="HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce""

for %%P in (%REG_PATHS%) do (
    for /f "tokens=1,*" %%A in ('reg query %%P 2^>nul ^| findstr /v "HKEY_"') do (
        if not "%%A"=="" (
            set /a COUNT+=1
            set "STARTUP_LIST=!STARTUP_LIST! [%%A]"
        )
    )
)

:: 4. 판정 로직
if %COUNT% gtr 0 (
    :: 시작 프로그램이 존재하면 관리자 검토가 필요하므로 '취약(검토 필요)' 판정
    set "RESULT=취약(검토)"
    set "STATUS_MSG=총 %COUNT%개의 시작 프로그램이 등록되어 있습니다. 목록: !STARTUP_LIST!"
) else (
    set "RESULT=양호"
    set "STATUS_MSG=등록된 시작 프로그램이 없습니다."
)

:: 5. 결과 출력 및 CSV 저장
echo [결과] : %RESULT%
echo [현황] : %STATUS_MSG%
echo ------------------------------------------------

:: CSV 파일 저장 (특수문자 콤마 제거 처리)
set "CLEAN_MSG=%STATUS_MSG:,= %"
echo "%CATEGORY%","%CODE%","%RISK%","%ITEM%","%RESULT%","%CLEAN_MSG%","%ACTION%" >> "%FULL_PATH%"

echo.
echo 점검 완료! 결과가 저장되었습니다: %FULL_PATH%
pause