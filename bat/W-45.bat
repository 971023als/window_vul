@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for IIS Web Service information hiding audit
set "csvFile=!resultDir!\IIS_Web_Service_Audit.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define audit details
set "category=서비스관리"
set "code=W-45"
set "riskLevel=상"
set "diagnosisItem=IIS 웹서비스 정보 숨김"
set "service=IIS"
set "diagnosisResult=양호"
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-45] IIS 웹서비스 정보 숨김 설정 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: IIS 커스텀 에러 페이지 설정이 적절하게 구성되어 있습니다. >> "!TMP1!"
echo [취약]: IIS 커스텀 에러 페이지 설정이 적절하지 않습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: IIS 커스텀 에러 페이지 설정 검사 (PowerShell 사용)
powershell -Command "& {
    $webService = Get-Service -Name 'W3SVC' -ErrorAction SilentlyContinue;
    if ($webService.Status -eq 'Running') {
        $webConfigPath = 'C:\inetpub\wwwroot\web.config';
        if (Test-Path $webConfigPath) {
            $webConfigContent = Get-Content $webConfigPath;
            $custErrPath = $webConfigContent | Select-String -Pattern 'customErrors mode=\"On\"';
            if ($custErrPath) {
                $status = 'OK: IIS 커스텀 에러 페이지 설정이 적절하게 구성되어 있습니다.';
            } else {
                $status = 'WARN: IIS 커스텀 에러 페이지 설정이 적절하지 않습니다.';
            }
        } else {
            $status = 'INFO: web.config 파일을 찾을 수 없습니다.';
        }
    } else {
        $status = 'INFO: World Wide Web Publishing Service가 실행되지 않고 있습니다.';
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p status=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\IIS_Web_Service_Audit.csv에서 확인하세요.
echo.

endlocal
pause
