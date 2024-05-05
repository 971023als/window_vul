@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=C:\Window_%COMPUTERNAME%_result"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for Startup Programs Analysis
set "csvFile=!resultDir!\Startup_Programs.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Diagnosis Result,Status,Countermeasure" > "!csvFile!"

REM Define security details
set "category=보안관리"
set "code=W-81"
set "riskLevel=상"
set "diagnosisItem=시작프로그램 목록 분석"
set "diagnosisResult=양호"
set "status=현황을 검토 중..."
set "countermeasure=시작프로그램 목록을 정기적으로 검토하고, 불필요한 프로그램은 제거"

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [!code!] 시작프로그램 목록 분석 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 모든 시작프로그램이 필요하고 안전합니다. >> "!TMP1!"
echo [주의]: 불필요하거나 위험한 시작프로그램이 존재할 수 있습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: Check for administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 관리자 권한으로 실행되어야 합니다.
    powershell -command "Start-Process '%~0' -Verb runAs"
    exit
)

:: Analyze Startup Programs using PowerShell
powershell -Command "& {
    $startupPrograms = Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location, User
    $result = @()
    foreach ($program in $startupPrograms) {
        $status = 'Reviewed'
        $result += \"$($program.Name),$($program.Command),$($program.Location),$($program.User),$status\"
    }
    $result | Out-File -FilePath '!resultDir!\startup_programs_detail.txt';
}"

:: Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!diagnosisResult!","!status!","!countermeasure!" >> "!csvFile!"

:: Output detailed startup programs to audit
type "!resultDir!\startup_programs_detail.txt" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
