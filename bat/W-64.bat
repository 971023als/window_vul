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
set "CODE=W-64"
set "RISK=중"
set "ITEM=윈도우 방화벽 설정"
set "ACTION=모든 네트워크 프로필(도메인, 개인, 공용)에 대해 윈도우 방화벽을 '사용'으로 설정"
set "CSV_FILE=Windows_Firewall_Check.csv"

:: 결과 폴더 생성 (현재 디렉터리에 result 폴더)
if not exist "result" mkdir "result"
set "FULL_PATH=result\%CSV_FILE%"

:: CSV 헤더 생성 (파일이 없을 경우에만)
if not exist "%FULL_PATH%" (
    echo Category,Code,Risk Level,Diagnosis Item,Result,Current Status,Remedial Action > "%FULL_PATH%"
)

echo ------------------------------------------------
echo CODE [%CODE%] %ITEM% 점검 시작
echo ------------------------------------------------

:: 3. 실제 점검 로직 (netsh 이용)
:: '상태' 라인에서 'OFF' 또는 '해제' 문자열이 있는지 확인
set "VULN=FALSE"
set "STATUS_LOG="

:: 모든 프로필의 상태를 조회하여 OFF가 있는지 검사
netsh advfirewall show allprofiles state | findstr /I "OFF 해제" > nul
if %errorLevel% equ 0 (
    set "RESULT=취약"
    set "STATUS_MSG=일부 방화벽 프로필이 비활성화되어 있습니다."
    set "COLOR=0C" :: 빨간색 느낌 (콘솔 전체 색 변경 주의)
) else (
    set "RESULT=양호"
    set "STATUS_MSG=모든 방화벽 프로필이 활성화되어 있습니다."
    set "COLOR=0A" :: 녹색 느낌
)

:: 4. 결과 출력 및 CSV 저장
echo [결과] : %RESULT%
echo [현황] : %STATUS_MSG%
echo ------------------------------------------------

:: CSV 파일에 결과 추가 (쉼표로 구분)
echo "%CATEGORY%","%CODE%","%RISK%","%ITEM%","%RESULT%","%STATUS_MSG%","%ACTION%" >> "%FULL_PATH%"

echo.
echo 점검 완료! 결과가 저장되었습니다: %FULL_PATH%
pause