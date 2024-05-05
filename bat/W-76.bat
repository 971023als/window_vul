@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=C:\Window_%COMPUTERNAME%_result"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for User Directory Permissions Analysis
set "csvFile=!resultDir!\User_Directory_Permissions.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=보안 관리"
set "code=W-76"
set "riskLevel=상"
set "diagnosisItem=사용자별 홈 디렉터리 권한 설정"
set "service=User Directory"
set "diagnosisResult="
set "status=점검 중..."
set "countermeasure=사용자별 홈 디렉터리 권한 설정"

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [!code!] 사용자 디렉토리 권한 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 적절한 권한 설정이 되어 있는 경우 >> "!TMP1!"
echo [취약]: 'Everyone'에게 전체 제어 권한이 있는 경우 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: Checking user directory permissions
echo 사용자 디렉토리 권한을 점검합니다...
for /D %%u in (C:\Users\*) do (
    set "userDir=%%u"
    set "permCheck="
    icacls "!userDir!" | find "Everyone:(F)" > nul && set "permCheck=취약"
    if not "!permCheck!"=="" (
        echo !userDir! has full control for Everyone >> "!TMP1!"
        set "diagnosisResult=취약"
    )
)

if "!diagnosisResult!"=="" (
    set "diagnosisResult=양호"
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!","!countermeasure!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
