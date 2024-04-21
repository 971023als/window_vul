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
echo 환경을 설정하고 있습니다...

:: Set up directory variables
set "분류=로그관리"
set "코드=W-57"
set "위험도=상"
set "진단항목=정책에 따른 시스템 로깅 설정"
set "진단결과=양호"
set "현황="
set "대응방안=정책에 따른 시스템 로깅 설정"

set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

:: Create and clean directories
if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: Export local security settings
secedit /export /cfg "%rawDir\Local_Security_Policy.txt"

:: Check audit policy settings
PowerShell -Command "
    $securitySettings = Get-Content '%rawDir\Local_Security_Policy.txt'
    $auditSettings = @('AuditLogonEvents', 'AuditPrivilegeUse', 'AuditPolicyChange', 'AuditDSAccess', 'AuditAccountLogon', 'AuditAccountManage')
    $incorrectlyConfigured = $false

    foreach ($setting in $auditSettings) {
        if ($securitySettings -notmatch '$setting.*1') {
            $incorrectlyConfigured = $true
            echo '$setting: No Auditing' | Out-File '%resultDir%\W-57-Result.csv' -Append
        }
    }

    if ($incorrectlyConfigured) {
        echo '취약' | Out-File '%resultDir%\W-57-Result.csv'
        echo '취약: Some audit events are not configured correctly.'
    } else {
        echo '양호, All audit events are correctly configured.' | Out-File '%resultDir%\W-57-Result.csv'
        echo '양호: All audit events are correctly configured.'
    }
"

:: Save results in CSV format
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사가 완료되었습니다. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
