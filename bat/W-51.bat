@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for Telnet security settings audit
set "csvFile=!resultDir!\Telnet_Security_Settings.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=계정관리"
set "code=W-51"
set "riskLevel=상"
set "diagnosisItem=Telnet 보안 설정"
set "service=Telnet"
set "diagnosisResult=양호"
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-51] Telnet 보안 설정 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: Telnet 서비스가 안전한 NTLM 인증 방식을 사용하고 있습니다. >> "!TMP1!"
echo [취약]: Telnet 서비스가 안전하지 않은 인증 방식을 사용하고 있습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: Telnet 서비스 보안 설정 검사 (PowerShell 사용)
powershell -Command "& {
    $telnetServiceStatus = Get-Service -Name 'TlntSvr' -ErrorAction SilentlyContinue;
    if ($telnetServiceStatus -and $telnetServiceStatus.Status -eq 'Running') {
        $telnetConfig = & tlntadmn.exe config;
        $authenticationMethod = $telnetConfig | Where-Object {$_ -match 'Authentication'};
        
        if ($authenticationMethod -match 'NTLM' -and $authenticationMethod -notmatch 'Password') {
            $status = 'OK: Telnet 서비스가 안전한 NTLM 인증 방식을 사용하고 있습니다.'
        } else {
            $status = 'WARN: Telnet 서비스가 안전하지 않은 인증 방식을 사용하고 있습니다. NTLM을 사용하고 비밀번호를 피하도록 권장됩니다.'
        }
    } else {
        $status = 'OK: Telnet 서비스가 실행되지 않거나 설치되지 않았으며, 이는 안전으로 간주됩니다.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p status=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\Telnet_Security_Settings.csv에서 확인하세요.
echo.

endlocal
pause
