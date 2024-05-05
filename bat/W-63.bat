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

:: Define CSV file for SAM file access status analysis
set "csvFile=!resultDir!\SAM_File_Access_Status.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

:: Define security details
set "category=보안관리"
set "code=W-63"
set "riskLevel=상"
set "diagnosisItem=SAM 파일 접근 통제 설정"
set "service=SAM Access"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [!code!] SAM File Access Control >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: Check SAM file permissions
PowerShell -Command "& {
    $samPermissions = icacls '$env:systemroot\system32\config\SAM'
    if ($samPermissions -notmatch 'Administrator|System') {
        $status = 'WARN: Permissions for the SAM file are not properly restricted.'
    } else {
        $status = 'OK: SAM file permissions are properly set.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p diagnosisResult=<temp.txt
del temp.txt

:: Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo Audit complete. Results can be found in !resultDir!\SAM_File_Access_Status.csv.
echo.

ENDLOCAL
pause
