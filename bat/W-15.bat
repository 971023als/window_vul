@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for anonymous SID/name translation policy analysis
set "csvFile=!resultDir!\Anonymous_SID_Name_Translation_Policy.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=계정관리"
set "code=W-15"
set "riskLevel=상"
set "diagnosisItem=익명 SID/이름 변환 허용"
set "service=보안 정책"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-15] 익명 SID/이름 변환 정책 설정 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [준수]: LSA 익명 이름 조회가 올바르게 비활성화되어 있습니다. >> "!TMP1!"
echo [비준수]: LSA 익명 이름 조회가 활성화되어 있습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 익명 SID/이름 변환 정책 설정 검사
for /f "tokens=2 delims== eol= " %%a in ('findstr /R "LSAAnonymousNameLookup = [0-9]*" "%rawPath%\Local_Security_Policy.txt"') do (
    set "LSAAnonymousNameLookup=%%a"
    if "!LSAAnonymousNameLookup!"=="0" (
        set "diagnosisResult=준수"
        set "status=준수 상태 감지됨: LSA 익명 이름 조회가 올바르게 비활성화되어 있습니다."
    ) else (
        set "diagnosisResult=취약"
        set "status=비준수 상태 감지됨: LSA 익명 이름 조회가 활성화되어 있습니다."
    )
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
