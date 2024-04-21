@echo off
SETLOCAL EnableDelayedExpansion

:: Request Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    PowerShell -Command "Start-Process PowerShell.exe -ArgumentList '-NoProfile', '-ExecutionPolicy Bypass', '-File', '%~f0', '-Verb', 'RunAs'"
    exit
)

:: Console environment settings
chcp 437 >nul
color 2A
cls
echo Setting up the environment...

:: Set up variables
set "분류=패치관리"
set "코드=W-55"
set "위험도=상"
set "진단항목=최신 HOT FIX 적용"
set "진단결과=양호"
set "현황="
set "대응방안=최신 HOT FIX 적용"

set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

:: Create and clean directories
if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: Check for hotfix
PowerShell -Command "
    $hotfixId = 'KB3214628'
    $hotfixCheck = Get-HotFix -Id $hotfixId -ErrorAction SilentlyContinue
    if ($hotfixCheck) {
        'W-55, 양호, 핫픽스 $hotfixId이 설치되어 있습니다., 이는 보안 상태가 양호함을 나타냅니다.' | Out-File '%resultDir%\W-55-Result.csv'
        echo '양호: 핫픽스 $hotfixId이 설치되어 있습니다.'
    } else {
        'W-55, 취약, 핫픽스 $hotfixId이 설치되어 있지 않습니다., 최신 핫픽스를 적용하는 것이 권장됩니다.' | Out-File '%resultDir%\W-55-Result.csv'
        echo '취약: 핫픽스 $hotfixId이 설치되어 있지 않습니다.'
    }
"

:: Save the result in CSV format
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo Audit complete. Results can be found in %resultDir%\AuditResults.csv.
ENDLOCAL
pause
