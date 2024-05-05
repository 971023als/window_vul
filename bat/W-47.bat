@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for SNMP community string complexity audit
set "csvFile=!resultDir!\SNMP_Community_String_Audit.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define audit details
set "category=서비스관리"
set "code=W-47"
set "riskLevel=상"
set "diagnosisItem=SNMP 서비스 커뮤니티스트링의 복잡성 설정"
set "service=SNMP"
set "diagnosisResult=양호"
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-47] SNMP 커뮤니티 스트링 설정 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: SNMP 커뮤니티 스트링이 적절하게 설정되어 있습니다. >> "!TMP1!"
echo [경고]: 기본 커뮤니티 스트링을 사용 중입니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: SNMP 서비스 커뮤니티 스트링 검사 (PowerShell 사용)
powershell -Command "& {
    $snmpService = Get-Service -Name 'SNMP' -ErrorAction SilentlyContinue;
    if ($snmpService -and $snmpService.Status -eq 'Running') {
        $communities = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities' -ErrorAction SilentlyContinue;
        if ($communities) {
            $defaultStrings = $communities.PSObject.Properties.Name -match 'public|private';
            if ($defaultStrings) {
                $status = 'WARN: 기본 커뮤니티 스트링(public 또는 private)을 사용 중입니다.'
            } else {
                $status = 'OK: 복잡성 높은 커뮤니티 스트링을 사용하고 있습니다.'
            }
        } else {
            $status = 'WARN: SNMP 설정을 검색할 수 없습니다.'
        }
    } else {
        $status = 'INFO: SNMP 서비스가 실행되지 않고 있습니다.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p status=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\SNMP_Community_String_Audit.csv에서 확인하세요.
echo.

endlocal
pause
