@echo off
SETLOCAL EnableDelayedExpansion

:: Request Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    PowerShell -Command "Start-Process PowerShell.exe -ArgumentList '-NoProfile', '-ExecutionPolicy Bypass', '-File', '%~f0', '-Verb', 'RunAs'"
    exit
)

:: Set console environment
chcp 437 >nul
color 2A
cls
echo Setting up the environment...

:: Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

:: Define CSV file for Antivirus update status analysis
set "csvFile=!resultDir!\Antivirus_Update_Status.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

:: Define security details
set "category=패치관리"
set "code=W-56"
set "riskLevel=상"
set "diagnosisItem=백신 프로그램 업데이트"
set "service=Antivirus"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-56] 백신 프로그램 업데이트 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: Check antivirus software status
PowerShell -Command "& {
    $avSoftware = Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntivirusProduct -ErrorAction SilentlyContinue
    if ($avSoftware) {
        $status = 'OK: 보안 프로그램이 설치되어 있으며 활성화되어 있습니다.'
    } else {
        $status = 'WARN: 보안 프로그램이 설치되어 있지 않거나 활성화되어 있지 않습니다.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p diagnosisResult=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\Antivirus_Update_Status.csv에서 확인하세요.
echo.

endlocal
pause
