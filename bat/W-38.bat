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
echo 감사 환경을 초기화 중입니다...

:: 감사 구성 변수 설정
set "분류=서비스관리"
set "코드=W-38"
set "위험도=상"
set "진단_항목=FTP 디렉토리 접근권한 설정"
set "진단_결과=양호"
set "현황="
set "대응방안=FTP 디렉토리 접근권한 설정"

:: 디렉터리 설정
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Audit_%computerName%_Raw"
set "resultDir=C:\Audit_%computerName%_Results"

if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: FTP 디렉토리 접근권한 검사
echo FTP 디렉토리 접근권한을 검사 중입니다...
PowerShell -Command "
    $isSecure = $true
    If (Test-Path '%rawDir%\FTP_PATH.txt') {
        Get-Content '%rawDir%\FTP_PATH.txt' | ForEach-Object {
            $filePath = $_
            $acl = Get-Acl $filePath
            $hasFullControl = $acl.Access | Where-Object {
                $_.FileSystemRights -match 'FullControl' -and $_.IdentityReference -eq 'Everyone'
            }
            if ($hasFullControl) {
                $isSecure = $false
            }
        }
    }
    if (!$isSecure) {
        'W-38, 위험, EVERYONE 그룹에 대한 FullControl 접근 권한이 발견되어 취약합니다.' | Out-File '%resultDir%\W-38-Result.csv'
        echo '위험: EVERYONE 그룹에 대한 FullControl 접근 권한이 발견되어 취약합니다.'
    } else {
        'W-38, 양호, FTP 디렉토리 접근권한이 적절히 설정됨.' | Out-File '%resultDir%\W-38-Result.csv'
        echo '양호: FTP 디렉토리 접근권한이 적절히 설정됨.'
    }
"

:: 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단_항목,진단_결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단_항목%,%진단_결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사 완료. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
