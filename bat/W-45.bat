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
set "코드=W-45"
set "위험도=상"
set "진단항목=IIS 웹서비스 정보 숨김"
set "진단결과=양호"
set "현황="
set "대응방안=IIS 웹서비스 정보 숨김"

:: 디렉터리 설정
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: IIS 커스텀 에러 페이지 설정 검사
echo IIS 커스텀 에러 페이지 설정을 검사 중입니다...
PowerShell -Command "
    $webService = Get-Service -Name 'W3SVC' -ErrorAction SilentlyContinue
    if ($webService.Status -eq 'Running') {
        $webConfigPath = 'C:\inetpub\wwwroot\web.config'
        if (Test-Path $webConfigPath) {
            $webConfigContent = Get-Content $webConfigPath
            $custErrPath = $webConfigContent | Select-String -Pattern 'customErrors mode=`"On`"'
            if ($custErrPath) {
                'W-45, 양호, IIS 커스텀 에러 페이지 설정이 적절하게 구성되어 보안이 강화되었습니다., ' | Out-File '%resultDir%\W-45-Result.csv'
                echo '양호: IIS 커스텀 에러 페이지 설정이 적절하게 구성되어 있습니다.'
            } else {
                'W-45, 취약, IIS 커스텀 에러 페이지 설정이 적절하지 않아 보안에 취약할 수 있습니다., 커스텀 에러 페이지 설정이 필요합니다.' | Out-File '%resultDir%\W-45-Result.csv'
                echo '취약: IIS 커스텀 에러 페이지 설정이 적절하지 않습니다.'
            }
        } else {
            'W-45, 정보, web.config 파일을 찾을 수 없습니다., 파일 위치 확인 필요.' | Out-File '%resultDir%\W-45-Result.csv'
            echo '정보: web.config 파일을 찾을 수 없습니다.'
        }
    } else {
        'W-45, 정보, World Wide Web Publishing Service가 실행되지 않고 있습니다., IIS 설정이 필요 없을 수 있습니다.' | Out-File '%resultDir%\W-45-Result.csv'
        echo '정보: World Wide Web Publishing Service가 실행되지 않고 있습니다.'
    }
"

:: 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사 완료. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
