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
set "코드=W-50"
set "위험도=상"
set "진단항목=HTTP/FTP/SMTP 배너 차단"
set "진단결과=양호"
set "현황="
set "대응방안=HTTP/FTP/SMTP 배너 차단"

:: 디렉터리 설정
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: 서비스 구성 검사
echo 서비스 구성을 검사 중입니다...
PowerShell -Command "
    $iisConfig = Get-Content '$env:WinDir\System32\Inetsrv\Config\applicationHost.Config'
    $ftpSites = $iisConfig | Select-String -Pattern 'ftpServer'
    $smtpConfig = Get-WmiObject -Query 'SELECT * FROM SmtpService' -Namespace 'root\MicrosoftIISv2'

    if (!$ftpSites -and !$smtpConfig) {
        'W-50, 양호, HTTP, FTP, SMTP 서비스는 현재 비활성화되어 있거나 배너가 적절하게 숨겨져 있습니다., ' | Out-File '%resultDir%\W-50-Result.csv'
        echo '양호: 서비스가 비활성화되어 있거나 배너가 적절하게 숨겨져 있습니다.'
    } else {
        'W-50, 경고, 하나 이상의 서비스가 배너 정보를 외부에 노출하고 있을 수 있습니다. 적절한 설정 변경이 필요합니다., ' | Out-File '%resultDir%\W-50-Result.csv'
        echo '경고: 서비스가 배너 정보를 외부에 노출하고 있습니다.'
    }
"

:: 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사 완료. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
