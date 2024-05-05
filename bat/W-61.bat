@echo off
SETLOCAL EnableDelayedExpansion

:: Request Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    PowerShell -Command "Start-Process cmd.exe -ArgumentList '/c %~f0' -Verb RunAs" -Wait
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

:: Define CSV file for directory permission analysis
set "csvFile=!resultDir!\Directory_Permission_Status.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

:: Define security details
set "category=로그관리"
set "code=W-61"
set "riskLevel=상"
set "diagnosisItem=원격에서 이벤트 로그 파일 접근 차단"
set "service=Event Log Directory Access"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-61] Event Log Directory Access Audit >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: Check directory permissions
PowerShell -Command "& {
    $directories = @('$env:systemroot\system32\logfiles', '$env:systemroot\system32\config')
    $vulnerabilityFound = $False

    foreach ($dir in $directories) {
        $acl = Get-Acl $dir
        foreach ($ace in $acl.Access) {
            If ($ace.IdentityReference -eq 'Everyone' -and $ace.FileSystemRights -like '*FullControl*') {
                $vulnerabilityFound = $True
                \"$status = 'WARN: Everyone group has full control over $dir. This is a vulnerability.'\"
                break
            }
        }
    }

    If (-not $vulnerabilityFound) {
        \"$status = 'OK: Directory permissions are properly restricted.'\"
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p diagnosisResult=<temp.txt
del temp.txt

:: Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo Audit complete. Results can be found in !resultDir!\Directory_Permission_Status.csv.
echo.

ENDLOCAL
pause
