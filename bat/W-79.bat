@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=C:\Window_%COMPUTERNAME%_result"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for NTFS Permissions Analysis
set "csvFile=!resultDir!\NTFS_Permissions.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=보안관리"
set "code=W-79"
set "riskLevel=상"
set "diagnosisItem=파일 및 디렉터리 보호"
set "service=NTFS"
set "diagnosisResult="
set "status=점검 중..."

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [!code!] NTFS 권한 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: NTFS 권한이 적절히 설정되어 있습니다. >> "!TMP1!"
echo [취약]: NTFS 권한 설정이 적절하지 않습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: Check for administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 관리자 권한으로 실행되어야 합니다.
    powershell -command "Start-Process '%~0' -Verb runAs"
    exit
)

:: Collect system info
systeminfo > "!resultDir!\systeminfo.txt"

:: NTFS permissions check using PowerShell
set "aclCheckPath=C:\"
powershell -Command "& {
    $acl = Get-Acl '%aclCheckPath%';
    $status = 'OK: NTFS 권한이 적절히 설정되어 있습니다.';
    foreach ($entry in $acl.Access) {
        if ($entry.IdentityReference -eq 'Everyone' -and $entry.FileSystemRights -eq 'FullControl') {
            $status = 'WARN: NTFS 권한 설정이 적절하지 않습니다.';
            break;
        }
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p diagnosisResult=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
