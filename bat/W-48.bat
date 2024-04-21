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
set "코드=W-48"
set "위험도=상"
set "진단항목=SNMP 허용된 관리자 설정"
set "진단결과=양호"
set "현황="
set "대응방안=SNMP 허용된 관리자 설정"

:: 디렉터리 설정
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: SNMP 허용된 관리자 설정 검사
echo SNMP 허용된 관리자 설정 상태를 검사 중입니다...
PowerShell -Command "
    $snmpService = Get-Service -Name SNMP -ErrorAction SilentlyContinue
    if ($snmpService.Status -eq 'Running') {
        $permittedManagers = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers' -ErrorAction SilentlyContinue
        if ($permittedManagers -and $permittedManagers.PSObject.Properties.Value) {
            'W-48, 양호, SNMP 서비스가 실행 중이며 허용된 관리자가 구성되어 있습니다. 해당 설정은 네트워크 보안을 강화하는 데 도움이 됩니다., ' | Out-File '%resultDir%\W-48-Result.csv'
            echo 양호: 허용된 관리자가 구성되어 있습니다.
        } else {
            'W-48, 경고, SNMP 서비스가 실행 중이지만 허용된 관리자가 명확하게 구성되지 않았습니다. SNMP 관리를 위한 보안 조치로 허용된 관리자를 명확하게 설정하는 것이 권장됩니다., ' | Out-File '%resultDir%\W-48-Result.csv'
            echo 경고: 허용된 관리자가 명확하게 구성되지 않았습니다.
        }
    } else {
        'W-48, 정보, SNMP 서비스가 실행되지 않고 있습니다., ' | Out-File '%resultDir%\W-48-Result.csv'
        echo 정보: SNMP 서비스가 실행되지 않고 있습니다.
    }
"

:: 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사 완료. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
