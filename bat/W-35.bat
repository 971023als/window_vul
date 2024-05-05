@echo off
setlocal enabledelayedexpansion

REM Define directories for storing raw and result data and create them if not exists
set "rawDir=C:\Audit_%COMPUTERNAME%_RawData"
set "resultDir=C:\Audit_%COMPUTERNAME%_Results"
if not exist "!rawDir!" mkdir "!rawDir!"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for WebDAV security audit results
set "csvFile=!resultDir!\W-35.csv"
echo "Category,Code,Risk Level,Audit Item,Audit Result,Current Status,Recommendation" > "!csvFile!"

REM Define audit details
set "category=계정 관리"
set "code=W-35"
set "riskLevel=높음"
set "auditItem=비밀번호 저장을 위한 복호화 가능 암호화 사용"
set "auditResult=양호"
set "status="
set "recommendation=비복호화 가능 암호화 사용 권장"

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [!code!] 웹DAV 보안 검사 수행 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: WebDAV 보안 감사 수행 (PowerShell 사용)
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {
    # 콘솔 환경 설정
    chcp 437 | Out-Null
    $host.UI.RawUI.BackgroundColor = 'DarkGreen'
    $host.UI.RawUI.ForegroundColor = 'Green'
    Clear-Host

    Write-Host 'WebDAV 보안 검사를 수행하고 있습니다...'
    $serviceStatus = (Get-Service W3SVC -ErrorAction SilentlyContinue).Status

    if ($serviceStatus -eq 'Running') {
        $webDavConfigurations = Select-String -Path '$env:SystemRoot\System32\inetsrv\config\applicationHost.config' -Pattern 'webdav' -AllMatches
        if ($webDavConfigurations) {
            foreach ($config in $webDavConfigurations) {
                $config.Line | Out-File -FilePath '!rawDir!\WebDAVConfigDetails.txt' -Append
            }
            $auditResult = '검토 필요: WebDAV 구성이 발견되었습니다.'
        } else {
            $auditResult = '조치 필요 없음: WebDAV가 적절하게 구성되었거나 존재하지 않습니다.'
        }
    } else {
        $auditResult = '조치 필요 없음: IIS 웹 게시 서비스가 실행 중이지 않습니다.'
    }

    \"$auditResult\" | Out-File -FilePath temp.txt;
    Pause
}"
set /p auditResult=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!auditItem!","!auditResult!","!status!","!recommendation!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
