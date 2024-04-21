@echo off
SETLOCAL EnableDelayedExpansion

:: 관리자 권한 요청
net session >nul 2>&1
if %errorLevel% neq 0 (
    PowerShell -Command "Start-Process PowerShell.exe -ArgumentList '-NoProfile', '-ExecutionPolicy Bypass', '-File', '%~f0', '-Verb', 'RunAs'"
    exit
)

:: 콘솔 환경 설정
chcp 437 >nul
color 2A
cls
echo 환경을 초기화 중입니다...

:: 감사 구성 변수 설정
set "분류=서비스관리"
set "코드=W-43"
set "위험도=상"
set "진단항목=최신 서비스팩 적용"
set "진단결과=양호"
set "현황="
set "대응방안=최신 서비스팩 적용"

:: 디렉터리 설정
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: OS 버전 및 서비스팩 진단
echo OS 버전 및 서비스팩을 진단 중입니다...
PowerShell -Command "
    $osInfo = Get-CimInstance Win32_OperatingSystem
    $osVersion = $osInfo.Version
    $servicePack = $osInfo.ServicePackMajorVersion

    if ($servicePack -eq 0) {
        'W-43, 취약, 최신 서비스팩이 적용되지 않았습니다., 최신 서비스팩 적용이 필요합니다.' | Out-File '%resultDir%\W-43-Result.csv'
        echo '취약: 최신 서비스팩이 적용되지 않았습니다.'
    } else {
        'W-43, 양호, 최신 서비스팩이 적용되어 있습니다., ' | Out-File '%resultDir%\W-43-Result.csv'
        echo '양호: 최신 서비스팩이 적용되어 있습니다.'
    }
"

:: 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사 완료. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
