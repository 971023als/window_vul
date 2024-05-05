@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for share permissions analysis
set "csvFile=!resultDir!\Shared_Folder_Permissions.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=서비스관리"
set "code=W-19"
set "riskLevel=상"
set "diagnosisItem=공유 권한 및 사용자 그룹 설정"
set "service=시스템 공유"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-19] 공유 폴더 접근 권한 분석 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 공유 설정 분석
net share > "%rawPath%\shares.txt"
for /f "tokens=1,* delims= " %%a in ('type "%rawPath%\shares.txt" ^| findstr /V "C:$ D:$ IPC$ ADMIN$ print$"') do (
    cacls "%%b" > "%rawPath%\%%a-permissions.txt"
    set "everyoneAccess="
    for /f "delims=" %%c in ('type "%rawPath%\%%a-permissions.txt" ^| findstr /C:"Everyone"') do (
        set "everyoneAccess=%%c"
        echo "문제 발견: 공유 폴더 '%%a'에 Everyone 그룹이 접근 가능: !everyoneAccess!" >> "!resultPath!\W-19.csv"
        set "진단결과=취약"
    )
    if not defined everyoneAccess (
        echo "문제 없음: 공유 폴더 '%%a' 보안 설정이 적절함, Everyone 그룹의 접근 제한됨." >> "!resultPath!\W-19.csv"
        set "진단결과=양호"
    )
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
