@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0Window_%COMPUTERNAME%_result"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for IIS CGI status analysis
set "csvFile=!resultDir!\W-24.csv"
echo "분류,코드,위험도,진단항목,진단결과,현황,대응방안" > "!csvFile!"

REM Define security details
set "category=서비스관리"
set "code=W-24"
set "riskLevel=상"
set "diagnosisItem=IIS CGI 실행 제한"
set "diagnosisResult="
set "status="
set "responsePlan="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-24] IIS CGI 실행 상태 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: IIS CGI 설정 분석
set "iisConfigFile=%WinDir%\System32\Inetsrv\Config\applicationHost.Config"
if exist "!iisConfigFile!" (
    type "!iisConfigFile!" > "!resultDir!\iis_setting.txt"
    for /f "delims=" %%a in ('type "!resultDir!\iis_setting.txt" ^| findstr /I "CGI"') do (
        set "cgiEnabled=%%a"
        if "!cgiEnabled!"=="<add name=\"CGI-exe\" enabled=\"true\"" (
            set "diagnosisResult=취약"
            set "status=CGI 실행이 활성화되어 있습니다."
            set "responsePlan=IIS CGI 실행 제한 조치 필요"
        ) else (
            set "diagnosisResult=양호"
            set "status=CGI 실행이 비활성화되어 있습니다."
            set "responsePlan=추가 조치 필요 없음"
        )
    )
)

:: Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!diagnosisResult!","!status!","!responsePlan!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 스크립트 실행 완료

endlocal
