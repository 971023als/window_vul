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
set "코드=W-49"
set "위험도=상"
set "진단항목=DNS 서비스 동적 업데이트 점검"
set "진단결과=양호"
set "현황="
set "대응방안=DNS 서비스 동적 업데이트 설정"

:: 디렉터리 설정
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: DNS 서비스 상태 검사
echo DNS 서비스 상태를 검사 중입니다...
PowerShell -Command "
    $dnsService = Get-Service -Name 'DNS' -ErrorAction SilentlyContinue
    if ($dnsService.Status -eq 'Running') {
        $allowUpdate = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\DNS Server\Zones' -ErrorAction SilentlyContinue).AllowUpdate
        if ($allowUpdate -eq 0) {
            'W-49, 양호, DNS 서비스가 활성화되어 있으나 동적 업데이트 권한이 설정되어 있지 않아 안전합니다., ' | Out-File '%resultDir%\W-49-Result.csv'
            echo '양호: 동적 업데이트 권한이 설정되어 있지 않아 안전합니다.'
        } else {
            'W-49, 경고, DNS 서비스가 활성화되어 있으나 동적 업데이트 권한이 설정되어 위험합니다., ' | Out-File '%resultDir%\W-49-Result.csv'
            echo '경고: 동적 업데이트 권한이 설정되어 위험합니다.'
        }
    } else {
        'W-49, 양호, DNS 서비스가 비활성화되어 있어 안전합니다., ' | Out-File '%resultDir%\W-49-Result.csv'
        echo '양호: DNS 서비스가 비활성화되어 있습니다.'
    }
"

:: 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사 완료. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
