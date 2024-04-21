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
echo 환경을 설정하고 있습니다...

:: Set up directory variables
set "분류=보안관리"
set "코드=W-62"
set "위험도=상"
set "진단항목=백신 프로그램 설치"
set "진단결과=양호"
set "현황="
set "대응방안=백신 프로그램 설치"

set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

:: Create and clean directories
if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: Check for antivirus software installation
PowerShell -Command "
    $softwareKeys = @('HKLM:\SOFTWARE\ESTsoft', 'HKLM:\SOFTWARE\AhnLab')
    $softwareInstalled = $False

    foreach ($key in $softwareKeys) {
        If (Test-Path $key) {
            $softwareInstalled = $True
            '양호, $key 백신 소프트웨어가 설치되어 있습니다.' | Out-File '%resultDir%\%코드%-Result.csv'
            echo '양호: $key 백신 소프트웨어가 설치되어 있습니다.'
            break
        }
    }

    If (-not $softwareInstalled) {
        '취약, ESTsoft 또는 AhnLab 백신 소프트웨어가 설치되지 않았습니다.' | Out-File '%resultDir%\%코드%-Result.csv'
        echo '취약: ESTsoft 또는 AhnLab 백신 소프트웨어가 설치되지 않았습니다.'
    }
"

:: Save results in CSV format
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사가 완료되었습니다. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
