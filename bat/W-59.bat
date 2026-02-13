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
set "CODE=W-59"
set "RISK=중"
set "ITEM=LAN Manager 인증 수준 적절성 점검"
set "ACTION=보안 옵션에서 '네트워크 보안: LAN Manager 인증 수준'을 'NTLMv2 응답만 보내기'로 설정"
set "CSV_FILE=LAN_Manager_Auth_Level_Check.csv"

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
:: 경로: HKLM\SYSTEM\CurrentControlSet\Control\Lsa
set "REG_PATH=HKLM\SYSTEM\CurrentControlSet\Control\Lsa"
set "LM_VAL="

for /f "tokens=3" %%A in ('reg query "%REG_PATH%" /v LmCompatibilityLevel 2^>nul') do (
    set "LM_VAL=%%A"
)

:: 4. 판정 로직
:: 0x3 (3): NTLMv2 응답만 보냄
:: 0x4 (4): NTLMv2 응답만 보냄. LM 거부
:: 0x5 (5): NTLMv2 응답만 보냄. LM 및 NTLM 거부
:: 위 3가지 중 하나면 양호, 그 외(0,1,2 또는 설정 없음)는 취약

if "!LM_VAL!"=="" (
    set "RESULT=취약"
    set "STATUS_MSG=LAN Manager 인증 수준이 레지스트리에 설정되어 있지 않습니다."
) else (
    if "!LM_VAL!"=="0x3" (
        set "RESULT=양호"
        set "STATUS_MSG=NTLMv2 응답만 보내기(3)로 설정되어 있습니다."
    ) else if "!LM_VAL!"=="0x4" (
        set "RESULT=양호"
        set "STATUS_MSG=NTLMv2 응답만 보내기. LM 거부(4)로 설정되어 있습니다."
    ) else if "!LM_VAL!"=="0x5" (
        set "RESULT=양호"
        set "STATUS_MSG=NTLMv2 응답만 보내기. LM 및 NTLM 거부(5)로 설정되어 있습니다."
    ) else (
        set "RESULT=취약"
        set "STATUS_MSG=취약한 인증 수준(!LM_VAL!)이 사용되고 있습니다."
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