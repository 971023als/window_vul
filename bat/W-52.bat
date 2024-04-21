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
set "코드=W-52"
set "위험도=상"
set "진단항목=불필요한 ODBC/OLE-DB 데이터 소스와 드라이브 제거"
set "진단결과=양호"
set "현황="
set "대응방안=불필요한 ODBC/OLE-DB 데이터 소스와 드라이브 제거"

:: 디렉터리 설정
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: ODBC 데이터 소스 설정 검사
echo ODBC 데이터 소스 설정을 검사 중입니다...
PowerShell -Command "
    $odbcDataSources = Get-ItemProperty 'HKLM:\SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources' -ErrorAction SilentlyContinue
    if ($odbcDataSources.PSObject.Properties.Name.Count -gt 0) {
        'W-52, 취약, ODBC 데이터 소스가 구성되어 있으며, 이는 필요하지 않을 경우 취약점이 될 수 있습니다. 현재 구성된 소스: '+$odbcDataSources.PSObject.Properties.Name | Out-File '%resultDir%\W-52-Result.csv'
        echo '취약: ODBC 데이터 소스가 구성되어 있습니다.'
    } else {
        'W-52, 양호, 불필요한 ODBC 데이터 소스가 구성되어 있지 않으며, 시스템은 안전합니다., ' | Out-File '%resultDir%\W-52-Result.csv'
        echo '양호: 불필요한 ODBC 데이터 소스가 구성되어 있지 않습니다.'
    }
"

:: 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사 완료. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
