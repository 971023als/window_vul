@echo off
setlocal enabledelayedexpansion

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
set "category=계정 관리"
set "code=W-36"
set "riskLevel=높음"
set "diagnosisItem=비밀번호 저장을 위한 복호화 가능한 암호화 사용"
set "service=Security Audit"
set "diagnosisResult=양호"
set "status="
set "mitigation=복호화 불가능한 암호화 방식 사용"

:: 경로 설정 및 디렉터리 생성
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Audit_%computerName%_Raw"
set "resultDir=C:\Audit_%computerName%_Results"

if not exist "%rawDir%" mkdir "%rawDir%"
if not exist "%resultDir%" mkdir "%resultDir%"

:: 보안 설정 및 시스템 정보 내보내기
secedit /export /cfg "%rawDir%\Local_Security_Policy.txt" >nul
systeminfo > "%rawDir%\SystemInfo.txt"

:: 로깅을 위한 파일 생성
set "TMP1=%~n0.log"
type nul > "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-36] 복호화 가능한 암호화 사용 문제 진단 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"
echo [양호]: 비밀번호 저장에 복호화 불가능한 암호화 사용 >> "!TMP1!"
echo [취약]: 비밀번호 저장에 복호화 가능한 암호화 사용 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 보안 감사 실행 및 결과 업데이트
echo 보안 감사를 수행 중입니다...
:: 예시: 결과 직접 업데이트 (실제 로직에 따라 변경 필요)
set "diagnosisResult=취약"
set "status=비밀번호 저장에 사용된 암호화가 복호화 가능합니다."

:: 결과 CSV 파일로 저장
set "csvFile=%resultDir%\W-36.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status,Mitigation" > "!csvFile!"
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!","!mitigation!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"
echo.

echo 감사 완료. 결과는 %resultDir%\W-36.csv에서 확인하세요.
endlocal
pause
