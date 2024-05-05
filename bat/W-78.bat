@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=C:\Window_%COMPUTERNAME%_result"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for Local Security and System Information Analysis
set "csvFile=!resultDir!\Local_Security_and_System_Info.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=보안관리"
set "code=W-78"
set "riskLevel=상"
set "diagnosisItem=보안 채널 데이터 디지털 암호화 또는 서명"
set "service=Security Channel"
set "diagnosisResult=양호"
set "status=점검 시작..."
set "countermeasure=보안 채널 데이터 디지털 암호화 또는 서명 조정"

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [!code!] 보안 채널 설정 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 보안 채널 설정이 적절합니다 >> "!TMP1!"
echo [취약]: 보안 채널 설정이 적절하지 않습니다 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 관리자 권한으로 실행되어야 합니다.
    powershell -command "Start-Process '%~0' -Verb runAs"
    exit
)

:: Setup directories
mkdir "!resultDir!\raw"

:: Export local security policy
secedit /export /cfg "!resultDir!\raw\Local_Security_Policy.txt"

:: Analyze system information
systeminfo > "!resultDir!\raw\systeminfo.txt"

:: Analyze IIS configuration if applicable
set "iisConfigPath=%WinDir%\System32\Inetsrv\Config\applicationHost.Config"
if exist "!iisConfigPath!" (
    findstr "physicalPath bindingInformation" "!iisConfigPath!" > "!resultDir!\raw\iis_setting.txt"
)

:: Analyze the security policy
set "securityPolicyPath=!resultDir!\raw\Local_Security_Policy.txt"
set "result=취약"
findstr "RequireSignOrSeal=1 SealSecureChannel=1 SignSecureChannel=1" "!securityPolicyPath!" >nul && set "result=양호"

:: Record the results
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!","!countermeasure!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 진단 결과가 저장되었습니다: "!csvFile!"
echo.

endlocal
