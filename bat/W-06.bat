@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for Administrators group membership analysis
set "csvFile=!resultDir!\Administrators_Group_Membership.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=계정관리"
set "code=W-06"
set "riskLevel=상"
set "diagnosisItem=관리자 그룹에 최소한의 사용자 포함"
set "service=관리자 그룹"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-06] 관리자 그룹 사용자 멤버십 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 관리자 그룹에 임시 또는 게스트 계정이 포함되지 않아 보안 정책을 준수합니다. >> "!TMP1!"
echo [취약]: 관리자 그룹에 임시 또는 게스트 계정('test', 'Guest')이 포함되어 있습니다; >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 관리자 그룹 멤버 검사
net localgroup Administrators > "%rawPath%\administrators.txt"

:: 진단 시작
set "진단결과=양호"
set "현황="

:: 관리자 그룹 내 비허용 사용자 확인
for /f "tokens=*" %%i in ('type "%rawPath%\administrators.txt" ^| findstr /C:"test" /C:"Guest"') do (
    set "진단결과=취약"
    set "현황=!현황!관리자 그룹에 임시 또는 게스트 계정('test', 'Guest')이 포함되어 있습니다; "
)

if "!진단결과!"=="양호" (
    set "현황=관리자 그룹에 임시 또는 게스트 계정이 포함되지 않아 보안 정책을 준수합니다."
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
