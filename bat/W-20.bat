@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultPath=%~dp0Window_%COMPUTERNAME%_result"
if not exist "!resultPath!" mkdir "!resultPath!"

REM Define CSV file for share removal analysis
set "csvFile=!resultPath!\W-20.csv"
echo "분류,코드,위험도,진단항목,진단결과,현황,대응방안" > "!csvFile!"

REM Define security details
set "category=서비스관리"
set "code=W-20"
set "riskLevel=상"
set "diagnosisItem=하드디스크 기본 공유 제거"
set "diagnosisResult="
set "status=기본 공유가 제거됨"
set "responsePlan=하드디스크 기본 공유 제거"

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-20] 기본 공유 제거 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: Collect system and share information
set "rawPath=%~dp0Window_%COMPUTERNAME%_raw"
if exist "!rawPath!" rmdir /s /q "!rawPath!"
mkdir "!rawPath!"

secedit /export /cfg "!rawPath!\Local_Security_Policy.txt"
systeminfo > "!rawPath!\systeminfo.txt"
net share > "!rawPath!\shares.txt"

:: Check for default shares
set "diagnosisResult=양호"
for /f "tokens=1,* delims= " %%a in ('type "!rawPath!\shares.txt" ^| findstr /C:"C$" /C:"ADMIN$" /C:"IPC$"') do (
    set "diagnosisResult=취약"
    set "status=기본 공유 %%a가 존재함"
)

:: Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!diagnosisResult!","!status!","!responsePlan!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 스크립트 실행 완료

endlocal
