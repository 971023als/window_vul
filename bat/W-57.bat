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

:: Define CSV file for System Logging Status analysis
set "csvFile=!resultDir!\System_Logging_Status.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

:: Define security details
set "category=로그관리"
set "code=W-57"
set "riskLevel=상"
set "diagnosisItem=정책에 따른 시스템 로깅 설정"
set "service=System Logging"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-57] 시스템 로깅 정책 설정 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: Export and check local security settings
secedit /export /cfg "%resultDir%\Local_Security_Policy.txt"
PowerShell -Command "& {
    $securitySettings = Get-Content '%resultDir%\Local_Security_Policy.txt'
    $auditSettings = @('AuditLogonEvents', 'AuditPrivilegeUse', 'AuditPolicyChange', 'AuditDSAccess', 'AuditAccountLogon', 'AuditAccountManage')
    $incorrectlyConfigured = $false

    foreach ($setting in $auditSettings) {
        if ($securitySettings -notmatch \"$setting.*1\") {
            $incorrectlyConfigured = $true
            echo '$setting: No Auditing' | Out-File '%resultDir%\W-57-Result.csv' -Append
        }
    }

    if ($incorrectlyConfigured) {
        \"$status\" = '취약: Some audit events are not configured correctly.'
    } else {
        \"$status\" = '양호: All audit events are correctly configured.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p diagnosisResult=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\System_Logging_Status.csv에서 확인하세요.
echo.

ENDLOCAL
pause
