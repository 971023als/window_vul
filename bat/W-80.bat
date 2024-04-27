@echo off
setlocal EnableDelayedExpansion

:: 관리자 권한 확인
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 관리자 권한으로 실행되어야 합니다.
    powershell -command "Start-Process '%~0' -Verb runAs"
    exit
)

:: 환경 설정
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Window_%computerName%_raw"
set "resultDir=C:\Window_%computerName%_result"

:: 디렉터리 생성 및 초기화
if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: 보안 정책 및 시스템 정보 수집
secedit /export /cfg "%rawDir%\Local_Security_Policy.txt"
systeminfo > "%rawDir%\systeminfo.txt"

:: NTFS 권한 검사 (기본 경로: C:\)
set "aclCheckPath=C:\"
set "result=취약"
set "status=NTFS 권한 설정이 적절하지 않습니다."
powershell -command "if ((Get-Acl %aclCheckPath%).AccessToString -match 'NT AUTHORITY') {set result=양호; set status=NTFS 권한이 적절히 설정되어 있습니다.;} else {set result=취약; set status=NTFS 권한 설정이 적절하지 않습니다.;}"

:: 결과 CSV 파일 저장
set "csvFile=%resultDir%\W-80-%computerName%.csv"
echo 분류,코드,위험도,진단 항목,진단 결과,현황,대응방안 > "%csvFile%"
echo 보안관리,W-80,상,컴퓨터 계정 암호 최대 사용 기간,!result!,!status!,컴퓨터 계정 암호 최대 사용 기간 >> "%csvFile%"

:: 결과 요약 파일 생성
type "%resultDir%\W-80-*" > "%resultDir%\security_audit_summary.txt"

:: 정리 작업
del /f /q "%rawDir%\*"
echo 스크립트 실행이 완료되었습니다. 결과는 %resultDir%에서 확인할 수 있습니다.
