@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for RDP session timeout settings audit
set "csvFile=!resultDir!\RDP_Session_Timeout_Settings.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=서비스관리"
set "code=W-53"
set "riskLevel=상"
set "diagnosisItem=원격터미널 접속 타임아웃 설정"
set "service=RDP"
set "diagnosisResult=양호"
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-53] 원격터미널 RDP 세션 타임아웃 설정 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: RDP 세션 타임아웃이 적절하게 구성되었습니다. >> "!TMP1!"
echo [취약]: RDP 세션 타임아웃이 설정되지 않았습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: RDP 세션 타임아웃 설정 검사 (PowerShell 사용)
powershell -Command "& {
    $rdpTcpSettings = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
    if ($rdpTcpSettings.MaxIdleTime -eq 0) {
        $status = 'WARN: RDP 세션 타임아웃이 설정되지 않았습니다. 이는 취약점이 될 수 있습니다.'
    } else {
        $status = 'OK: RDP 세션 타임아웃이 적절하게 구성되었습니다.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p diagnosisResult=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\RDP_Session_Timeout_Settings.csv에서 확인하세요.
echo.

endlocal
pause
