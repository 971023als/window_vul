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
set "코드=W-39"
set "위험도=상"
set "진단항목=Anonymous FTP 금지"
set "진단결과=양호"
set "현황="
set "대응방안=Anonymous FTP 금지"

:: 디렉터리 설정
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Audit_%computerName%_Raw"
set "resultDir=C:\Audit_%computerName%_Results"

if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: 진단 로직 실행
echo FTP 설정을 진단 중입니다...
PowerShell -Command "
    $isSecure = $true
    $ftpSettings = Get-Content '%rawDir%\FTP_Settings.txt' -ErrorAction SilentlyContinue
    if ($ftpSettings -match 'anonymous') {
        $isSecure = $false
    }
    if (!$isSecure) {
        'W-39, 위험, Anonymous FTP 접근이 허용되어 있습니다.' | Out-File '%resultDir%\W-39-Result.csv'
        echo '위험: Anonymous FTP 접근이 허용되어 있습니다.'
    } else {
        'W-39, 양호, Anonymous FTP 접근이 금지되어 있습니다.' | Out-File '%resultDir%\W-39-Result.csv'
        echo '양호: Anonymous FTP 접근이 금지되어 있습니다.'
    }
"

:: 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사 완료. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
