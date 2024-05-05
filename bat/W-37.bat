@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for security audit results
set "csvFile=!resultDir!\AuditResults.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=계정 관리"
set "code=W-37"
set "riskLevel=높음"
set "diagnosisItem=비밀번호 저장을 위한 복호화 가능한 암호화 사용"
set "service=Security Audit"
set "diagnosisResult=양호"
set "status="
set "mitigation=복호화 불가능한 암호화 방식 사용"

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-37] Microsoft FTP 서비스 감사 실행 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: Microsoft FTP 서비스가 비활성화 되어 있는 경우 >> "!TMP1!"
echo [취약]: Microsoft FTP 서비스가 활성화 되어 있는 경우 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 감사 실행
powershell -Command "& {
    $service = Get-Service -Name 'MSFTPSvc' -ErrorAction SilentlyContinue;
    if ($service -and $service.Status -eq 'Running') {
        $status = 'WARN: Microsoft FTP 서비스가 활성화되어 있습니다.'
    } else {
        $status = 'OK: Microsoft FTP 서비스가 비활성화되어 있습니다.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p diagnosisResult=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!","!mitigation!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
echo.

endlocal
pause
