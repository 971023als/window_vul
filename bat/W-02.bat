@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for guest account status analysis
set "csvFile=!resultDir!\Guest_Account_Status.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Status,Diagnosis Result,Remedial Action" > "!csvFile!"

REM Define security details
set "category=계정관리"
set "code=W-02"
set "riskLevel=상"
set "diagnosisItem=Guest 계정 상태"
set "status="
set "diagnosisResult="
set "remedialAction=Guest 계정 상태 변경"

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-02] 게스트 계정 상태 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 게스트 계정이 비활성화 상태로 유지되고 있으므로 안전합니다. >> "!TMP1!"
echo [취약]: 게스트 계정이 활성화 되어 있는 위험 상태로, 조치가 필요합니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 게스트 계정 활성화 여부 확인
findstr /C:"Account active               Yes" "%rawPath%\guest_info.txt" >nul && (
    set "diagnosisResult=취약"
    set "status=게스트 계정이 활성화 되어 있는 위험 상태로, 조치가 필요합니다."
) || (
    set "diagnosisResult=양호"
    set "status=게스트 계정이 비활성화 상태로 유지되고 있으므로 안전합니다."
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!status!","!diagnosisResult!","!remedialAction!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
