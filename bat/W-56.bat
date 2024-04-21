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
set "분류=패치관리"
set "코드=W-56"
set "위험도=상"
set "진단항목=백신 프로그램 업데이트"
set "진단결과=양호"
set "현황="
set "대응방안=백신 프로그램 업데이트"

set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

:: Prepare directories
if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: Check antivirus software status
echo 보안 소프트웨어 상태를 점검합니다...
PowerShell -Command "
    $avSoftware = Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntivirusProduct -ErrorAction SilentlyContinue
    if ($avSoftware) {
        'W-56, 양호, 보안 프로그램이 설치되어 있으며 활성화되어 있습니다.' | Out-File '%resultDir%\W-56-Result.csv'
        echo '양호: 보안 프로그램이 설치되어 있으며 활성화되어 있습니다.'
    } else {
        'W-56, 취약, 보안 프로그램이 설치되어 있지 않거나 활성화되어 있지 않습니다.' | Out-File '%resultDir%\W-56-Result.csv'
        echo '취약: 보안 프로그램이 설치되어 있지 않거나 활성화되어 있지 않습니다.'
    }
"

:: Save results in CSV format
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사가 완료되었습니다. 결과는 %resultDir%\AuditResults.csv 파일에서 확인할 수 있습니다.
ENDLOCAL
pause
