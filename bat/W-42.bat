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
set "분류=계정관리"
set "코드=W-42"
set "위험도=상"
set "진단항목=RDS(Remote Data Services) 제거"
set "진단결과=양호"
set "현황="
set "대응방안=RDS(Remote Data Services) 제거"

:: 디렉터리 설정
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: RDS 상태 점검
echo RDS 상태를 점검 중입니다...
PowerShell -Command "
    $webService = Get-Service -Name 'W3SVC' -ErrorAction SilentlyContinue
    if ($webService -and $webService.Status -eq 'Running') {
        'W-42, 위험, 웹 서비스가 실행 중입니다. RDS가 활성화되어 있을 수 있습니다., 웹 서비스를 비활성화하거나 RDS 관련 구성을 제거하세요.' | Out-File '%resultDir%\W-42-Result.csv'
        echo '위험: 웹 서비스가 실행 중입니다. RDS가 활성화되어 있을 수 있습니다.'
    } else {
        'W-42, 양호, 웹 서비스가 실행되지 않거나 설치되지 않았습니다. RDS 제거 상태가 양호합니다., ' | Out-File '%resultDir%\W-42-Result.csv'
        echo '양호: 웹 서비스가 실행되지 않거나 설치되지 않았습니다.'
    }
"

:: 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사 완료. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
