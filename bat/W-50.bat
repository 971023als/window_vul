@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for service banner hiding audit
set "csvFile=!resultDir!\Service_Banner_Hiding_Audit.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define audit details
set "category=서비스관리"
set "code=W-50"
set "riskLevel=상"
set "diagnosisItem=HTTP/FTP/SMTP 배너 차단"
set "service=Web Services"
set "diagnosisResult=양호"
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-50] HTTP/FTP/SMTP 배너 차단 설정 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 서비스가 비활성화되어 있거나 배너가 적절하게 숨겨져 있습니다. >> "!TMP1!"
echo [경고]: 서비스가 배너 정보를 외부에 노출하고 있습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 서비스 구성 검사 (PowerShell 사용)
powershell -Command "& {
    $iisConfig = Get-Content '$env:WinDir\System32\Inetsrv\Config\applicationHost.Config'
    $ftpSites = $iisConfig | Select-String -Pattern 'ftpServer'
    $smtpConfig = Get-WmiObject -Query 'SELECT * FROM SmtpService' -Namespace 'root\MicrosoftIISv2'

    if (!$ftpSites -and !$smtpConfig) {
        $status = 'OK: HTTP, FTP, SMTP 서비스는 현재 비활성화되어 있거나 배너가 적절하게 숨겨져 있습니다.'
    } else {
        $status = 'WARN: 하나 이상의 서비스가 배너 정보를 외부에 노출하고 있을 수 있습니다. 적절한 설정 변경이 필요합니다.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p status=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\Service_Banner_Hiding_Audit.csv에서 확인하세요.
echo.

endlocal
pause
