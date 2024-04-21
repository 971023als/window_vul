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

:: 디렉터리 생성
if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: 보안 정책 내보내기
secedit /export /cfg "%rawDir%\Local_Security_Policy.txt"

:: 시스템 정보 수집
systeminfo > "%rawDir%\systeminfo.txt"

:: IIS 설정 분석
set "iisConfigPath=%WinDir%\System32\Inetsrv\Config\applicationHost.Config"
if exist "%iisConfigPath%" (
    findstr "physicalPath bindingInformation" "%iisConfigPath%" > "%rawDir%\iis_setting.txt"
)

:: 보안 정책 분석
set "securityPolicyPath=%rawDir%\Local_Security_Policy.txt"
set "result=취약"
findstr "RequireSignOrSeal=1 SealSecureChannel=1 SignSecureChannel=1" "%securityPolicyPath%" >nul && set "result=양호"

:: 결과 기록
set "resultFile=%resultDir%\W-Window-%computerName%-result.csv"
echo 분류,코드,위험도,진단 항목,진단 결과,현황,대응방안 > "%resultFile%"
echo 보안관리,W-78,상,보안 채널 데이터 디지털 암호화 또는 서명,%result%,보안 채널 설정이 적절합니다,보안 채널 데이터 디지털 암호화 또는 서명 >> "%resultFile%"

echo 진단 결과가 저장되었습니다: %resultFile%

:: 정리
del /f /q "%rawDir%\*"
echo 스크립트가 완료되었습니다.
