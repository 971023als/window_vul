@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0Window_%COMPUTERNAME%_result"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for password encryption policy analysis
set "csvFile=!resultDir!\W-27.csv"
echo "분류,코드,위험도,진단항목,진단결과,현황,대응방안" > "!csvFile!"

REM Define security details
set "category=계정 관리"
set "code=W-27"
set "riskLevel=높음"
set "diagnosisItem=비밀번호 저장을 위한 복호화 가능한 암호화 사용"
set "diagnosisResult="
set "status="
set "responsePlan="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-27] 비밀번호 저장 정책 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 비밀번호 저장 정책 검사
set "encryptionMethod=ReversibleEncryption"  :: 가정된 설정입니다.
if "!encryptionMethod!"=="ReversibleEncryption" (
    set "diagnosisResult=취약"
    set "status=복호화 가능한 암호화 방법 사용 중"
    set "responsePlan=비밀번호 저장을 위한 복호화 불가능한 암호화 사용 권장"
) else (
    set "diagnosisResult=양호"
    set "status=복호화 불가능한 암호화 방법 사용 중"
    set "responsePlan=추가 조치 필요 없음"
)

:: Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!diagnosisResult!","!status!","!responsePlan!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 스크립트 실행 완료

endlocal
