@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for ODBC/OLE-DB data sources and drivers audit
set "csvFile=!resultDir!\ODBC_OLEDB_Audit.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define audit details
set "category=서비스관리"
set "code=W-52"
set "riskLevel=상"
set "diagnosisItem=불필요한 ODBC/OLE-DB 데이터 소스와 드라이브 제거"
set "service=ODBC/OLE-DB"
set "diagnosisResult=양호"
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-52] 불필요한 ODBC/OLE-DB 설정 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 불필요한 ODBC/OLE-DB 데이터 소스가 없습니다. >> "!TMP1!"
echo [취약]: 불필요한 ODBC/OLE-DB 데이터 소스가 구성되어 있습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: ODBC/OLE-DB 데이터 소스 설정 검사 (PowerShell 사용)
powershell -Command "& {
    $odbcDataSources = Get-ItemProperty 'HKLM:\SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources' -ErrorAction SilentlyContinue;
    if ($odbcDataSources.PSObject.Properties.Name.Count -gt 0) {
        $status = 'WARN: ODBC 데이터 소스가 구성되어 있으며, 이는 필요하지 않을 경우 취약점이 될 수 있습니다. 현재 구성된 소스: ' + ($odbcDataSources.PSObject.Properties.Name -join ', ')
    } else {
        $status = 'OK: 불필요한 ODBC 데이터 소스가 구성되어 있지 않으며, 시스템은 안전합니다.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p diagnosisResult=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\ODBC_OLEDB_Audit.csv에서 확인하세요.
echo.

endlocal
pause
