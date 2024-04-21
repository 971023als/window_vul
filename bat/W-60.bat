@echo off
SETLOCAL EnableDelayedExpansion

:: Request Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    PowerShell -Command "Start-Process powershell.exe -ArgumentList '-NoProfile', '-ExecutionPolicy Bypass', '-File', '%~f0', '-Verb', 'RunAs'" -Wait
    exit
)

:: Console environment settings
chcp 437 >nul
color 2A
cls
echo 환경을 설정하고 있습니다...

:: Set up directory variables
set "분류=로그관리"
set "코드=W-60"
set "위험도=상"
set "진단항목=이벤트 로그 관리 설정"
set "진단결과=양호"
set "현황="
set "대응방안=이벤트 로그 관리 설정 조정"

set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

:: Create and clean directories
if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: Check Event Log settings
echo 이벤트 로그 설정을 검사합니다...
PowerShell -Command "
    $eventLogKeys = @('Application', 'Security', 'System')
    $inadequateSettings = $False

    foreach ($key in $eventLogKeys) {
        $path = 'HKLM:\SYSTEM\CurrentControlSet\Services\Eventlog\$key'
        $maxSize = (Get-ItemProperty -Path $path -Name 'MaxSize').MaxSize
        $retention = (Get-ItemProperty -Path $path -Name 'Retention').Retention
        If ($maxSize -lt 10485760 -or $retention -eq 0) {
            $inadequateSettings = $True
            echo '$key log is inadequately configured with MaxSize: $maxSize bytes and Retention: $retention' | Out-File '%resultDir%\%코드%-Result.csv' -Append
        }
    }

    if ($inadequateSettings) {
        echo '%코드%, 취약, Some event logs are not configured correctly.' | Out-File '%resultDir%\%코드%-Result.csv'
        echo '취약: Some event logs are not configured correctly.'
    } else {
        echo '%코드%, 양호, All event logs are adequately configured.' | Out-File '%resultDir%\%코드%-Result.csv'
        echo '양호: All event logs are adequately configured.'
    }
"

:: Save results in CSV format
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사가 완료되었습니다. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
