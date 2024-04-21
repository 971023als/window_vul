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
set "분류=패치관리"
set "코드=W-54"
set "위험도=상"
set "진단항목=예약된 작업에 의심스러운 명령이 등록되어 있는지 점검"
set "진단결과=양호"
set "현황="
set "대응방안=예약된 작업에 의심스러운 명령이 등록되어 있는지 점검"

:: 디렉터리 설정
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: 스케줄러 작업 검사
echo 스케줄러 작업을 검사 중입니다...
PowerShell -Command "
    $schedulerTasks = schtasks /query /fo CSV | ConvertFrom-Csv
    if ($schedulerTasks) {
        $suspiciousTasks = $schedulerTasks | Where-Object { $_.TaskName -like '*admin*' -or $_.TaskName -like '*hack*' }
        if ($suspiciousTasks) {
            'W-54, 경고, 의심스러운 스케줄러 작업이 발견되었습니다: '+$suspiciousTasks.TaskName | Out-File '%resultDir%\W-54-Result.csv'
            echo '경고: 의심스러운 스케줄러 작업이 발견되었습니다.'
        } else {
            'W-54, 양호, 의심스러운 스케줄러 작업이 없으며, 시스템은 안전합니다., ' | Out-File '%resultDir%\W-54-Result.csv'
            echo '양호: 의심스러운 스케줄러 작업이 없습니다.'
        }
    } else {
        'W-54, 양호, 스케줄러에 예약된 작업이 없으며, 이는 보안 상태가 안전함을 나타냅니다., ' | Out-File '%resultDir%\W-54-Result.csv'
        echo '양호: 스케줄러에 예약된 작업이 없습니다.'
    }
"

:: 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사 완료. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
