@echo off
SETLOCAL EnableDelayedExpansion

:: Request Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    PowerShell -Command "Start-Process powershell.exe -ArgumentList '-NoProfile', '-ExecutionPolicy Bypass', '-File', '%~f0', '-Verb', 'RunAs'"
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

:: Define CSV file for Remote Registry service status analysis
set "csvFile=!resultDir!\Remote_Registry_Status.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

:: Define security details
set "category=로그관리"
set "code=W-59"
set "riskLevel=상"
set "diagnosisItem=원격으로 액세스할 수 있는 레지스트리 경로"
set "service=Remote Registry"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-59] Remote Registry Access Path Vulnerability >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: Check Remote Registry service status (PowerShell 사용)
powershell -Command "& {
    $remoteRegistryStatus = Get-Service -Name 'RemoteRegistry' -ErrorAction SilentlyContinue;
    if ($remoteRegistryStatus -and $remoteRegistryStatus.Status -eq 'Running') {
        $status = 'WARN: Remote Registry Service is enabled, which is a risk.'
    } else {
        $status = 'OK: Remote Registry Service is disabled, which is secure.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p diagnosisResult=<temp.txt
del temp.txt

:: Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo Audit complete. Results can be found in %resultDir%\Remote_Registry_Status.csv.
echo.

ENDLOCAL
pause
