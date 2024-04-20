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

:: IIS 설정 파일 분석 및 디렉토리 접근 권한 검사
set "iisConfigFile=%env:WinDir%\System32\Inetsrv\Config\applicationHost.Config"
if exist "!iisConfigFile!" (
    type "!iisConfigFile!" > "%rawPath%\iis_setting.txt"
    for /f "delims=" %%a in ('type "%rawPath%\iis_setting.txt" ^| findstr /I "CGI"') do (
        set "cgiEnabled=%%a"
        if "!cgiEnabled!"=="<add name=\"CGI-exe\" enabled=\"false\"" (
            set "cgiStatus=Disabled"
        ) else (
            set "cgiStatus=Enabled"
        )
    )
)

:: 진단 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단항목,진단결과,현황,대응방안 > "%resultPath%\W-24.csv"
if "!cgiStatus!"=="Enabled" (
    echo 서비스관리,W-24,상,IIS CGI 실행 제한,취약,CGI 실행이 활성화되어 있습니다.,IIS CGI 실행 제한 조치 필요 >> "%resultPath%\W-24.csv"
) else (
    echo 서비스관리,W-24,상,IIS CGI 실행 제한,양호,CGI 실행이 비활성화되어 있습니다.,추가 조치 필요 없음 >> "%resultPath%\W-24.csv"
)

:: 스크립트 실행 완료 메시지
echo 스크립트 실행 완료
