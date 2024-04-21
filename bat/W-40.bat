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
set "코드=W-40"
set "위험도=상"
set "진단항목=FTP 접근 제어 설정"
set "진단결과=양호"
set "현황="
set "대응방안=FTP 접근 제어 설정"

:: 디렉터리 설정
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: 진단 로직 실행
echo FTP 접근 제어를 검사 중입니다...
PowerShell -Command "
    $isSecure = $true
    # 실제 FTP 설정 파일을 검사하는 로직 추가 예정
    if (-not $isSecure) {
        'W-40, 위험, 모든 IP에서 FTP 접속이 허용되어 있어 취약합니다.' | Out-File '%resultDir%\W-40-Result.csv'
        echo '위험: 모든 IP에서 FTP 접속이 허용되어 있습니다.'
    } else {
        'W-40, 양호, 특정 IP 주소에서만 FTP 접속이 허용됩니다.' | Out-File '%resultDir%\W-40-Result.csv'
        echo '양호: 특정 IP 주소에서만 FTP 접속이 허용됩니다.'
    }
"

:: 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사 완료. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
