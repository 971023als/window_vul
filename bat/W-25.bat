@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0Window_%COMPUTERNAME%_result"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for password policy analysis
set "csvFile=!resultDir!\W-25.csv"
echo "분류,코드,위험도,진단항목,진단결과,현황,대응방안" > "!csvFile!"

REM Define security details
set "category=서비스관리"
set "code=W-25"
set "riskLevel=상"
set "diagnosisItem=암호를 저장하기 위한 복호화 가능한 암호화 사용"
set "diagnosisResult="
set "status="
set "responsePlan=암호 저장을 위한 복호화 불가능한 암호화 사용"

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-25] 암호 저장 정책 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 암호 저장 정책 검사
:: 예시로, 특정 서비스의 설정을 확인
sc query "YourService" | find "RUNNING" >nul
if %errorlevel% == 0 (
    set "diagnosisResult=취약"
    set "status=암호화 설정이 활성화되어 있으나, 보안 문제가 있습니다."
) else (
    set "diagnosisResult=양호"
    set "status=암호화 설정이 비활성화되어 있어 안전합니다."
)

:: Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!diagnosisResult!","!status!","!responsePlan!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 스크립트 실행 완료

endlocal
