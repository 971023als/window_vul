@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=C:\Window_%COMPUTERNAME%_result"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for Computer Account Password Policy Analysis
set "csvFile=!resultDir!\Computer_Account_Password_Policy.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=보안관리"
set "code=W-80"
set "riskLevel=상"
set "diagnosisItem=컴퓨터 계정 암호 최대 사용 기간"
set "service=Password Policy"
set "diagnosisResult="
set "status=점검 중..."

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [!code!] 컴퓨터 계정 암호 정책 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 암호 정책이 적절히 설정되어 있습니다. >> "!TMP1!"
echo [취약]: 암호 정책이 적절하지 않게 설정되어 있습니다. >> "!TMP1!"
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

:: Check NTFS permissions and password policy using PowerShell
set "aclCheckPath=C:\"
powershell -Command "& {
    $policy = secedit /export /cfg '%resultDir%\Local_Security_Policy.txt';
    .\ParseSecurityPolicy '%resultDir%\Local_Security_Policy.txt' | Out-File -FilePath temp.txt;
}"
set /p diagnosisResult=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
