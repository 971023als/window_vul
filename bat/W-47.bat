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
set "코드=W-47"
set "위험도=상"
set "진단항목=SNMP 서비스 커뮤니티스트링의 복잡성 설정"
set "진단결과=양호"
set "현황="
set "대응방안=SNMP 서비스 커뮤니티스트링의 복잡성 설정"

:: 디렉터리 설정
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: SNMP 서비스 커뮤니티 스트링 검사
echo SNMP 서비스 커뮤니티 스트링 상태를 검사 중입니다...
PowerShell -Command "
    $snmpService = Get-Service -Name 'SNMP' -ErrorAction SilentlyContinue
    if ($snmpService -and $snmpService.Status -eq 'Running') {
        $communities = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities' -ErrorAction SilentlyContinue
        if ($communities) {
            $defaultStrings = $communities.PSObject.Properties.Name -match 'public|private'
            if ($defaultStrings) {
                'W-47, 경고, SNMP 서비스가 실행 중이며 기본 커뮤니티 스트링인 public 또는 private를 사용하고 있습니다., 복잡성 높은 커뮤니티 스트링으로 변경하십시오.' | Out-File '%resultDir%\W-47-Result.csv'
                echo '경고: 기본 커뮤니티 스트링을 사용 중입니다.'
            } else {
                'W-47, 양호, SNMP 서비스가 실행 중이지만, 기본 커뮤니티 스트링을 사용하고 있지 않습니다., ' | Out-File '%resultDir%\W-47-Result.csv'
                echo '양호: 기본 커뮤니티 스트링을 사용하고 있지 않습니다.'
            }
        } else {
            'W-47, 경고, SNMP 설정을 검색할 수 없습니다., SNMP 설정을 검토하십시오.' | Out-File '%resultDir%\W-47-Result.csv'
            echo '경고: SNMP 설정을 검색할 수 없습니다.'
        }
    } else {
        'W-47, 정보, SNMP 서비스가 실행되지 않고 있습니다., ' | Out-File '%resultDir%\W-47-Result.csv'
        echo '정보: SNMP 서비스가 실행되지 않고 있습니다.'
    }
"

:: 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사 완료. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
