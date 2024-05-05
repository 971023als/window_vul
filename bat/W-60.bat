@echo off
SETLOCAL EnableDelayedExpansion

:: Request Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    PowerShell -Command "Start-Process powershell.exe -ArgumentList '-NoProfile', '-ExecutionPolicy Bypass', '-File', '%~f0', '-Verb', 'RunAs'" -Wait
    exit
)

:: Console environment settings
chcp 437 >nul
color 2A
cls
echo Setting up the environment...

:: Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

:: Define CSV file for Event Log management status analysis
set "csvFile=!resultDir!\Event_Log_Management_Status.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

:: Define security details
set "category=로그관리"
set "code=W-60"
set "riskLevel=상"
set "diagnosisItem=이벤트 로그 관리 설정"
set "service=Event Log"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-60] Event Log Configuration Audit >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: Check Event Log settings
echo Checking Event Log settings...
PowerShell -Command "& {
    $eventLogKeys = @('Application', 'Security', 'System')
    $inadequateSettings = $False

    foreach ($key in $eventLogKeys) {
        $path = 'HKLM:\SYSTEM\CurrentControlSet\Services\Eventlog\$key'
        $maxSize = (Get-ItemProperty -Path $path -Name 'MaxSize').MaxSize
        $retention = (Get-ItemProperty -Path $path -Name 'Retention').Retention
        If ($maxSize -lt 10485760 -or $retention -eq 0) {
            $inadequateSettings = $True
            \"$key log is inadequately configured with MaxSize: $maxSize bytes and Retention: $retention\" | Out-File '%resultDir%\W-60-Result.csv' -Append
        }
    }

    if ($inadequateSettings) {
        \"$status = 'WARN: Some event logs are not configured correctly.'\"
    } else {
        \"$status = 'OK: All event logs are adequately configured.'\"
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p diagnosisResult=<temp.txt
del temp.txt

:: Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo Audit complete. Results can be found in !resultDir!\Event_Log_Management_Status.csv.
echo.

ENDLOCAL
pause
