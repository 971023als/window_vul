@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for FTP anonymous access audit
set "csvFile=!resultDir!\FTP_Anonymous_Access_Audit.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define audit details
set "category=서비스관리"
set "code=W-39"
set "riskLevel=상"
set "diagnosisItem=Anonymous FTP 금지"
set "service=FTP"
set "diagnosisResult=양호"
set "status="
set "mitigation=Anonymous FTP 금지"

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-39] Anonymous FTP 접근 금지 감사 실행 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: Anonymous FTP 접근이 금지되어 있는 경우 >> "!TMP1!"
echo [취약]: Anonymous FTP 접근이 허용되어 있는 경우 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: Anonymous FTP 접근 설정 검사 (PowerShell 사용)
powershell -Command "& {
    $isSecure = $true
    $ftpSettings = Get-Content '%rawDir%\FTP_Settings.txt' -ErrorAction SilentlyContinue
    if ($ftpSettings -match 'anonymous') {
        $isSecure = $false
    }
    if (!$isSecure) {
        $status = 'WARN: Anonymous FTP 접근이 허용되어 있습니다.'
    } else {
        $status = 'OK: Anonymous FTP 접근이 금지되어 있습니다.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p status=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!","!mitigation!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\FTP_Anonymous_Access_Audit.csv에서 확인하세요.
echo.

endlocal
pause
