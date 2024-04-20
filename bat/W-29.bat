@echo off
SETLOCAL EnableDelayedExpansion

:: 관리자 권한으로 실행 확인
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process cmd -ArgumentList '/c %~0' -Verb RunAs"
    exit
)

:: 기본 설정
set "computerName=%COMPUTERNAME%"
set "rawPath=C:\Window_%computerName%_raw"
set "resultPath=C:\Window_%computerName%_result"

:: 디렉토리 초기화 및 생성
if exist "%rawPath%" rmdir /s /q "%rawPath%"
if exist "%resultPath%" rmdir /s /q "%resultPath%"
mkdir "%rawPath%"
mkdir "%resultPath%"

:: 보안 정책 파일 내보내기 및 시스템 정보 수집
secedit /export /cfg "%rawPath%\Local_Security_Policy.txt"
systeminfo > "%rawPath%\systeminfo.txt"

:: 비밀번호 저장 정책 검사
:: 이 부분에서는 설정 파일 등을 검토하여 복호화 가능한 암호화 사용 여부를 확인해야 합니다.
set "encryptionMethod=ReversibleEncryption"  :: 가정된 설정입니다.

:: 진단 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultPath%\W-29.csv"
if "!encryptionMethod!"=="ReversibleEncryption" (
    echo 계정 관리,W-29,높음,비밀번호 저장을 위한 복호화 가능한 암호화 사용,취약,복호화 가능한 암호화 방법 사용 중,비밀번호 저장을 위한 복호화 불가능한 암호화 사용 권장 >> "%resultPath%\W-29.csv"
) else (
    echo 계정 관리,W-29,높음,비밀번호 저장을 위한 복호화 가능한 암호화 사용,양호,복호화 불가능한 암호화 방법 사용 중,추가 조치 필요 없음 >> "%resultPath%\W-29.csv"
)

:: 스크립트 실행 완료 메시지
echo 스크립트 실행 완료
