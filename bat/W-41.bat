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
set "코드=W-41"
set "위험도=상"
set "진단항목=DNS Zone Transfer 설정"
set "진단결과=양호"
set "현황="
set "대응방안=DNS Zone Transfer 설정"

:: 디렉터리 설정
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: DNS 보안 설정 점검
echo DNS 보안 설정을 점검 중입니다...
PowerShell -Command "
    $dnsService = Get-Service 'DNS' -ErrorAction SilentlyContinue
    if ($dnsService.Status -eq 'Running') {
        $dnsZonesRegPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\DNS Server\Zones'
        $zoneKeys = Get-ChildItem -Path $dnsZonesRegPath -ErrorAction SilentlyContinue
        $zoneSecurityIssues = $false

        foreach ($zone in $zoneKeys) {
            $zoneData = Get-ItemProperty -Path $zone.PSPath -Name 'SecureSecondaries' -ErrorAction SilentlyContinue
            if ($zoneData -and $zoneData.SecureSecondaries -ne 2) {
                $zoneSecurityIssues = $true
                break
            }
        }

        if (-not $zoneSecurityIssues) {
            'W-41, 양호, DNS 전송 설정이 안전하게 구성되어 있습니다.' | Out-File '%resultDir%\W-41-Result.csv'
            echo '양호: DNS 전송 설정이 안전하게 구성되어 있습니다.'
        } else {
            'W-41, 취약, DNS 전송 설정이 취약한 구성으로 되어 있습니다. DNS 전송 설정을 보안 강화를 위해 수정해야 합니다.' | Out-File '%resultDir%\W-41-Result.csv'
            echo '취약: DNS 전송 설정이 취약한 구성으로 되어 있습니다.'
        }
    } else {
        'W-41, 정보, DNS 서비스가 실행 중이지 않습니다.' | Out-File '%resultDir%\W-41-Result.csv'
        echo '정보: DNS 서비스가 실행 중이지 않습니다.'
    }
"

:: 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사 완료. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
