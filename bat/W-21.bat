@echo off
setlocal enabledelayedexpansion

REM Define directories to store raw data and results, create if not exists
set "rawPath=%~dp0Window_%COMPUTERNAME%_raw"
set "resultPath=%~dp0Window_%COMPUTERNAME%_result"
if not exist "!rawPath!" mkdir "!rawPath!"
if not exist "!resultPath!" mkdir "!resultPath!"

REM Define CSV file for unnecessary services analysis
set "csvFile=!resultPath!\W-21.csv"
echo "분류,코드,위험도,진단항목,진단결과,현황,대응방안" > "!csvFile!"

REM Define security details
set "category=서비스관리"
set "code=W-21"
set "riskLevel=상"
set "diagnosisItem=불필요한 서비스 제거"
set "diagnosisResult=Status Report"
set "status=상태 보고"
set "responsePlan=불필요한 서비스 제거 조치"

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-21] 불필요한 서비스 제거 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

REM Security policy export and system information collection
secedit /export /cfg "!rawPath!\Local_Security_Policy.txt"
systeminfo > "!rawPath!\systeminfo.txt"

REM Check for specific unnecessary services
set "servicesToCheck=Alerter ClipBook Messenger 'Simple TCP/IP Services'"
for %%s in (%servicesToCheck%) do (
    sc query %%s | findstr /I "STATE" > nul
    if errorlevel 1 (
        echo %%s,Not Installed,Not Applicable >> "!csvFile!"
    ) else (
        for /f "tokens=3" %%t in ('sc query %%s ^| findstr /I "STATE"') do (
            set state=%%t
            if "!state!"=="4  RUNNING" (
                echo %%s,Installed,Running >> "!csvFile!"
            ) else (
                echo %%s,Installed,Not Running >> "!csvFile!"
            )
        )
    )
)

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 스크립트 실행 완료

endlocal
