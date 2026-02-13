@echo off
setlocal enabledelayedexpansion

REM 결과 저장 디렉토리 설정 및 생성
set "resultDir=%~dp0result"
if not exist "!resultDir!" mkdir "!resultDir!"

REM CSV 결과 파일 설정 (헤더 작성)
set "csvFile=!resultDir!\Admin_Account_Name_Check.csv"
echo "Category","Code","Risk Level","Diagnosis Item","Result","Current Status","Remedial Action" > "!csvFile!"

REM 보안 항목 정보 설정
set "category=계정관리"
set "code=W-01"
set "riskLevel=상"
set "diagnosisItem=Administrator 계정 이름 바꾸기"
set "remedialAction=Administrator 계정 이름 변경 (secpol.msc)"

REM 로그 파일 설정
set "TMP1=!resultDir!\%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-01] 관리자 계정 이름 변경 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"
echo [양호]: 관리자 계정 이름이 "Administrator"가 아닌 다른 이름으로 변경된 경우 >> "!TMP1!"
echo [취약]: 관리자 계정 이름이 "Administrator"로 유지되고 있는 경우 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [*] 시스템에서 관리자(RID 500) 계정명을 조회 중... >> "!TMP1!"

:: 1. WMIC를 사용하여 SID가 500으로 끝나는(기본 관리자) 계정의 실제 이름을 가져옴
set "currentAdminName="
for /f "tokens=2 delims==" %%A in ('wmic useraccount where "SID like 'S-1-5-%%-500'" get name /value 2^>nul') do (
    set "currentAdminName=%%A"
)

:: 공백 제거
set "currentAdminName=!currentAdminName: =!"

:: 2. 결과 판정 로직
if "!currentAdminName!"=="" (
    set "result=오류"
    set "currentStatus=관리자 계정 정보를 가져오는데 실패했습니다."
) else (
    echo 현재 확인된 관리자 계정명: [!currentAdminName!] >> "!TMP1!"
    
    if /i "!currentAdminName!"=="Administrator" (
        set "result=취약"
        set "currentStatus=관리자 계정의 기본 이름(Administrator)이 변경되지 않았습니다."
    ) else (
        set "result=양호"
        set "currentStatus=관리자 계정 이름이 [!currentAdminName!](으)로 변경되어 있습니다."
    )
)

REM CSV 파일에 결과 기록
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!result!","!currentStatus!","!remedialAction!" >> "!csvFile!"

REM 로그 출력 및 마감
echo 결과: !result! >> "!TMP1!"
echo 현황: !currentStatus! >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

type "!TMP1!"
echo.
echo 점검이 완료되었습니다. 
echo 결과 리포트: !csvFile!
echo 상세 로그: !TMP1!

endlocal
pause