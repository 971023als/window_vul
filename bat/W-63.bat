@echo off
SETLOCAL EnableDelayedExpansion

:: Request Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    PowerShell -Command "Start-Process powershell.exe -ArgumentList '-NoProfile', '-ExecutionPolicy Bypass', '-File', '%~f0', '-Verb', 'RunAs'" -Wait
    exit
)

:: Set console environment
chcp 437 >nul
color 2A
cls
echo 환경을 초기화 중입니다...

:: Set up directory variables
set "분류=보안관리"
set "코드=W-63"
set "위험도=상"
set "진단항목=SAM 파일 접근 통제 설정"
set "진단결과=양호"
set "현황="
set "대응방안=SAM 파일 접근 통제 설정"

set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

:: Create and clean directories
if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: Check SAM file permissions
PowerShell -Command "
    $samPermissions = icacls '$env:systemroot\system32\config\SAM'
    If ($samPermissions -notmatch 'Administrator|System') {
        '$코드, 취약, Administrator 또는 System 그룹 외 다른 권한이 SAM 파일에 대해 발견되었습니다.' | Out-File '%resultDir%\%코드%-Result.csv'
        echo '취약: Administrator 또는 System 그룹 외 다른 권한이 SAM 파일에 대해 발견되었습니다.'
    } Else {
        '$코드, 양호, Administrator 및 System 그룹 권한만이 SAM 파일에 설정되어 있습니다.' | Out-File '%resultDir%\%코드%-Result.csv'
        echo '양호: Administrator 및 System 그룹 권한만이 SAM 파일에 설정되어 있습니다.'
    }
"

:: Save results in CSV format
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사가 완료되었습니다. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
