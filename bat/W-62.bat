@echo off
SETLOCAL EnableDelayedExpansion

:: Request Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    PowerShell -Command "Start-Process powershell.exe -ArgumentList '-NoProfile', '-ExecutionPolicy Bypass', '-File', '%~f0', '-Verb', 'RunAs'" -Wait
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

:: Define CSV file for antivirus software status analysis
set "csvFile=!resultDir!\Antivirus_Software_Status.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

:: Define security details
set "category=보안관리"
set "code=W-62"
set "riskLevel=상"
set "diagnosisItem=백신 프로그램 설치"
set "service=Antivirus"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [!code!] Antivirus Installation Check >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: Check for antivirus software installation
PowerShell -Command "& {
    $softwareKeys = @('HKLM:\\SOFTWARE\\ESTsoft', 'HKLM:\\SOFTWARE\\AhnLab')
    $softwareInstalled = $False
    foreach ($key in $softwareKeys) {
        If (Test-Path $key) {
            $softwareInstalled = $True
            $status = 'OK: Antivirus software installed at '+$key
            break
        }
    }

    If (-not $softwareInstalled) {
        $status = 'WARN: No ESTsoft or AhnLab antivirus software installed.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p diagnosisResult=<temp.txt
del temp.txt

:: Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo Audit complete. Results can be found in !resultDir!\Antivirus_Software_Status.csv.
echo.

ENDLOCAL
pause
