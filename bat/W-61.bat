@echo off
SETLOCAL EnableDelayedExpansion

:: Request Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    PowerShell -Command "Start-Process cmd.exe -ArgumentList '/c %~f0' -Verb RunAs" -Wait
    exit
)

:: Set console environment
chcp 437 >nul
color 2A
cls
echo 환경을 초기화 중입니다...

:: Set up directory variables
set "분류=로그관리"
set "코드=W-61"
set "위험도=상"
set "진단항목=원격에서 이벤트 로그 파일 접근 차단"
set "진단결과=양호"
set "현황="
set "대응방안=원격에서 이벤트 로그 파일 접근 차단"

set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

:: Create and clean directories
if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: Check directory permissions
PowerShell -Command "
    $directories = @('$env:systemroot\system32\logfiles', '$env:systemroot\system32\config')
    $vulnerabilityFound = $False

    foreach ($dir in $directories) {
        $acl = Get-Acl $dir
        foreach ($ace in $acl.Access) {
            If ($ace.IdentityReference -eq 'Everyone' -and $ace.FileSystemRights -like '*FullControl*') {
                $vulnerabilityFound = $True
                '$코드, 취약, Everyone 그룹이 $dir 에 전체 제어 권한을 가지고 있습니다.' | Out-File '%resultDir%\%코드%-Result.csv' -Append
                echo '취약: Everyone 그룹이 $dir 에 전체 제어 권한을 가지고 있습니다.'
                break
            }
        }
    }

    If (-not $vulnerabilityFound) {
        '$코드, 양호, 주요 디렉터리에 Everyone 그룹 권한이 적절하게 제한되어 있습니다.' | Out-File '%resultDir%\%코드%-Result.csv'
        echo '양호: 주요 디렉터리에 Everyone 그룹 권한이 적절하게 제한되어 있습니다.'
    }
"

:: Save results in CSV format
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단항목%,%진단결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사가 완료되었습니다. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
