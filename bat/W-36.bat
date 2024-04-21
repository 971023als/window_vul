@echo off
SETLOCAL EnableDelayedExpansion

:: 관리자 권한 요청
net session >nul 2>&1
if %errorLevel% neq 0 (
    PowerShell -Command "Start-Process cmd.exe -ArgumentList '/c %~f0' -Verb RunAs"
    exit
)

:: 콘솔 환경 설정
chcp 437 >nul
color 2A
cls
echo 감사 환경을 초기화 중입니다...

:: 환경 변수 설정
set "분류=계정 관리"
set "코드=W-36"
set "위험도=높음"
set "진단_항목=비밀번호 저장을 위한 복호화 가능한 암호화 사용"
set "진단_결과=양호" 
set "현황="
set "대응방안=복호화 불가능한 암호화 방식 사용"

:: 감사 환경 준비
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Audit_%computerName%_Raw"
set "resultDir=C:\Audit_%computerName%_Results"

if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: 로컬 보안 정책 및 시스템 정보 내보내기
secedit /export /cfg "%rawDir%\Local_Security_Policy.txt" >nul
systeminfo > "%rawDir%\SystemInfo.txt"

:: 보안 감사 실행 및 결과 업데이트
echo 보안 감사를 수행 중입니다...
:: 예시: 결과 직접 업데이트 (실제 로직에 따라 변경 필요)
set "진단_결과=취약"
set "현황=비밀번호 저장에 사용된 암호화가 복호화 가능합니다."

:: CSV 파일로 결과 저장
echo 분류,코드,위험도,진단_항목,진단_결과,현황,대응방안 > "%resultDir%\W-36.csv"
echo %분류%,%코드%,%위험도%,%진단_항목%,%진단_결과%,%현황%,%대응방안% >> "%resultDir%\W-36.csv"

echo 감사 완료. 결과는 %resultDir%\W-36.csv에서 확인하세요.
ENDLOCAL
pause
