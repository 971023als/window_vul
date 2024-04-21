@echo off
SETLOCAL EnableDelayedExpansion

:: Request Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    PowerShell -Command "Start-Process powershell.exe -ArgumentList '-NoProfile', '-ExecutionPolicy Bypass', '-File', '%~f0', '-Verb', 'RunAs'"
    exit
)

:: Set console environment
chcp 437 >nul
color 2A
cls
echo 환경을 설정하고 있습니다...

:: Set up variables
set "분류=로그관리"
set "코드=W-59"
set "위험도=상"
set "진단항목=원격으로 액세스할 수 있는 레지스트리 경로"
set "진단결과=양호"
set "현황="
set "대응방안=원격으로 액세스할 수 있는 레지스트리 경로 차단"

set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

:: Prepare directories
if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: Check Remote Registry service status
echo 원격 레지스트리 서비스 상태를 검사합니다...
PowerShell -Command "
    $remoteRegistryStatus = Get-Service -Name 'RemoteRegistry' -ErrorAction SilentlyContinue
    if ($remoteRegistryStatus -and $remoteRegistryStatus.Status -eq 'Running') {
        'W-59, 취약, Remote Registry Service가 활성화되어 있으며, 이는 위험합니다.' | Out-File '%resultDir%\W-59-Result.csv'
        echo '취약: Remote Registry Service가 활성화되어 있습니다.'
    } else {
        'W-59, 양호, Remote Registry Service가 비활성화되어 있으며, 이는 안전합니다.' | Out-File '%resultDir%\W-59-Result.csv'
        echo '양호: Remote Registry Service가 비활성화되어 있습니다.'
    }
"

:: Save results in CSV format
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사가 완료되었습니다. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
