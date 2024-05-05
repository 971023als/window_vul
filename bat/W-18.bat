@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for Remote Desktop Users group membership analysis
set "csvFile=!resultDir!\Remote_Desktop_Users_Group.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=계정관리"
set "code=W-18"
set "riskLevel=상"
set "diagnosisItem=원격터미널 접속 가능한 사용자 그룹 제한"
set "service=보안 정책"
set "diagnosisResult="
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-18] 원격 데스크톱 사용자 그룹 멤버십 설정 검사 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 'Remote Desktop Users' 그룹에 무단 사용자가 없음. 준수 상태가 확인됨. >> "!TMP1!"
echo [취약]: 무단 사용자가 'Remote Desktop Users' 그룹에 포함됨. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 원격 데스크톱 사용자 그룹 설정 검사
net localgroup "Remote Desktop Users" > "%rawPath%\RemoteDesktopUsers.txt"
type "%rawPath%\RemoteDesktopUsers.txt" | find /i "account_name" > nul
if %errorlevel% == 0 (
    set "diagnosisResult=취약"
    set "status=무단 사용자가 'Remote Desktop Users' 그룹에 포함됨."
) else (
    set "diagnosisResult=양호"
    set "status='Remote Desktop Users' 그룹에 무단 사용자가 없음. 준수 상태가 확인됨."
)

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo.

endlocal
