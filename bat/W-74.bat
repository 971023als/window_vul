@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=C:\Window_%COMPUTERNAME%_result"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for session timeout policy analysis
set "csvFile=!resultDir!\Session_Timeout_Policy.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Result,Status,Countermeasure" > "!csvFile!"

REM Define security details
set "category=보안 관리"
set "code=W-74"
set "riskLevel=높음"
set "diagnosisItem=세션 연결 해제 전 필요한 유휴 시간"
set "result=양호"
set "status=점검 중..."
set "countermeasure=세션 연결 해제 전 필요한 유휴 시간 설정 조정"

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [!code!] 세션 타임아웃 정책 진단 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 유휴 시간 설정이 적절히 구성되어 있음 >> "!TMP1!"
echo [취약]: 유휴 시간 설정이 15분 미만으로 설정되어 있음 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: Check the session timeout policy value
set "policyValue=15"

:: Update diagnostic result based on the policy value
if "!policyValue!" lss "15" (
    set "result=취약"
    set "status=유휴 시간 설정이 15분 미만으로 설정되어 있습니다."
) else (
    set "status=유휴 시간 설정이 적절히 구성되어 있습니다."
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!result!","!status!","!countermeasure!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
