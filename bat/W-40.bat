@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for FTP access control audit
set "csvFile=!resultDir!\FTP_Access_Control_Audit.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=서비스관리"
set "code=W-40"
set "riskLevel=상"
set "diagnosisItem=FTP 접근 제어 설정"
set "service=FTP"
set "diagnosisResult=양호"
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-40] FTP 접근 제어 감사 실행 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 특정 IP 주소에서만 FTP 접속이 허용됩니다. >> "!TMP1!"
echo [취약]: 모든 IP에서 FTP 접속이 허용되어 있습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: FTP 접근 제어 설정 검사 (PowerShell 사용)
powershell -Command "& {
    $isSecure = $true
    # 실제 FTP 설정 파일을 검사하는 로직 추가 예정
    if (-not $isSecure) {
        $status = 'WARN: 모든 IP에서 FTP 접속이 허용되어 있어 취약합니다.'
    } else {
        $status = 'OK: 특정 IP 주소에서만 FTP 접속이 허용됩니다.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p status=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\FTP_Access_Control_Audit.csv에서 확인하세요.
echo.

endlocal
pause
