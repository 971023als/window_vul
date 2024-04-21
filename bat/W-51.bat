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
set "코드=W-51"
set "위험도=상"
set "진단항목=Telnet 보안 설정"
set "진단결과=양호"
set "현황="
set "대응방안=Telnet 보안 설정"

:: 디렉터리 설정
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: Telnet 서비스 보안 설정 검사
echo Telnet 서비스 보안 설정을 검사 중입니다...
PowerShell -Command "
    $telnetServiceStatus = Get-Service -Name 'TlntSvr' -ErrorAction SilentlyContinue
    if ($telnetServiceStatus -and $telnetServiceStatus.Status -eq 'Running') {
        $telnetConfig = & tlntadmn.exe config
        $authenticationMethod = $telnetConfig | Where-Object {$_ -match 'Authentication'}

        if ($authenticationMethod -match 'NTLM' -and $authenticationMethod -notmatch 'Password') {
            'W-51, 양호, Telnet 서비스가 안전한 NTLM 인증 방식을 사용하고 있습니다., ' | Out-File '%resultDir%\W-51-Result.csv'
            echo '양호: Telnet 서비스가 안전한 NTLM 인증 방식을 사용하고 있습니다.'
        } else {
            'W-51, 취약, Telnet 서비스가 안전하지 않은 인증 방식을 사용하고 있습니다. NTLM을 사용하고 비밀번호를 피하도록 권장됩니다., ' | Out-File '%resultDir%\W-51-Result.csv'
            echo '취약: Telnet 서비스가 안전하지 않은 인증 방식을 사용하고 있습니다.'
        }
    } else {
        'W-51, 양호, Telnet 서비스가 실행되지 않거나 설치되지 않았으며, 이는 안전으로 간주됩니다., ' | Out-File '%resultDir%\W-51-Result.csv'
        echo '양호: Telnet 서비스가 실행되지 않거나 설치되지 않았습니다.'
    }
"

:: 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사 완료. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
