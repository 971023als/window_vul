@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0Window_%COMPUTERNAME%_result"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for IIS service status analysis
set "csvFile=!resultDir!\W-22.csv"
echo "분류,코드,위험도,진단항목,진단결과,현황,대응방안" > "!csvFile!"

REM Define security details
set "category=서비스관리"
set "code=W-22"
set "riskLevel=상"
set "diagnosisItem=IIS 서비스 구동 점검"
set "diagnosisResult="
set "status="
set "responsePlan=IIS 서비스 구동 점검"

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-22] IIS 서비스 구동 상태 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: IIS 설정 분석 및 서비스 상태 확인
set "iisConfigFile=%WinDir%\System32\Inetsrv\Config\applicationHost.Config"
if exist "!iisConfigFile!" (
    type "!iisConfigFile!" > "!resultDir!\iis_setting.txt"
    for /f "delims=" %%a in ('type "!resultDir!\iis_setting.txt" ^| findstr /I "physicalPath bindingInformation"') do (
        echo %%a >> "!resultDir!\iis_path1.txt"
    )
)

sc query W3SVC | find "RUNNING" >nul
if !errorlevel! == 0 (
    set "diagnosisResult=취약"
    set "status='World Wide Web Publishing Service'가 활성화되어 있습니다."
) else (
    set "diagnosisResult=양호"
    set "status='World Wide Web Publishing Service'가 비활성화되어 있습니다."
)

:: Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!diagnosisResult!","!status!","!responsePlan!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 스크립트 실행 완료

endlocal
