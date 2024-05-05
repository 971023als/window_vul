@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=C:\Window_%COMPUTERNAME%_result"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for SQL Server Authentication Mode Analysis
set "csvFile=!resultDir!\SQL_Server_Auth_Mode.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=보안관리"
set "code=W-82"
set "riskLevel=상"
set "diagnosisItem=Windows 인증 모드 사용"
set "service=SQL Server"
set "diagnosisResult="
set "status=진단 중..."

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [!code!] SQL 서버 인증 모드 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: Windows 인증 모드가 활성화되어 있습니다. >> "!TMP1!"
echo [취약]: Windows 인증 모드가 비활성화되어 있습니다. 혼합 모드 인증이 사용 중입니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: Check for administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 관리자 권한으로 실행되어야 합니다.
    powershell -command "Start-Process '%~0' -Verb runAs"
    exit
)

:: SQL Server authentication mode check using PowerShell
powershell -Command "& {
    Try {
        $sqlServerInstance = 'SQLServerName'  # Replace with your actual SQL Server instance name
        $sqlNamespace = 'ROOT\Microsoft\SqlServer\ComputerManagement' + ((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances | ForEach-Object { $_.Substring($_.length - 2, 2) })
        $authModeQuery = 'SELECT * FROM SqlServiceAdvancedProperty WHERE SQLServiceType = 1 AND PropertyName = ''IsIntegratedSecurityOnly'''
        $authMode = Get-WmiObject -Query $authModeQuery -Namespace $sqlNamespace | Select-Object -ExpandProperty PropertyValue

        if ($authMode -eq 1) {
            \"$status = 'OK: Windows 인증 모드가 활성화되어 있습니다.'\"
        } else {
            \"$status = 'WARN: Windows 인증 모드가 비활성화되어 있습니다. 혼합 모드 인증이 사용 중입니다.'\"
        }
        \$status | Out-File -FilePath temp.txt
    } Catch {
        \"Error checking SQL Server authentication mode: $_\" | Out-File -FilePath temp.txt
    }
}"
set /p diagnosisResult=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
