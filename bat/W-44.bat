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
set "코드=W-44"
set "위험도=상"
set "진단항목=터미널 서비스 암호화 수준 설정"
set "진단결과=양호"
set "현황="
set "대응방안=터미널 서비스 암호화 수준 설정"

:: 디렉터리 설정
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: RDP 최소 암호화 수준 검사
echo RDP 최소 암호화 수준을 검사 중입니다...
PowerShell -Command "
    $regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
    $minEncryptionLevel = (Get-ItemProperty -Path $regPath -Name 'MinEncryptionLevel' -ErrorAction SilentlyContinue).MinEncryptionLevel

    if ($minEncryptionLevel -and $minEncryptionLevel -gt 1) {
        'W-44, 양호, RDP 최소 암호화 수준이 적절히 설정되어 있습니다., ' | Out-File '%resultDir%\W-44-Result.csv'
        echo '양호: RDP 최소 암호화 수준이 적절히 설정되어 있습니다.'
    } else {
        'W-44, 취약, RDP 최소 암호화 수준이 낮게 설정되어 있어 보안에 취약할 수 있습니다., 터미널 서비스 암호화 수준을 높여야 합니다.' | Out-File '%resultDir%\W-44-Result.csv'
        echo '취약: RDP 최소 암호화 수준이 낮게 설정되어 있습니다.'
    }
"

:: 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사 완료. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
