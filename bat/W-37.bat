@echo off
SETLOCAL

:: 관리자 권한 요청
PowerShell -Command "if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { Start-Process PowerShell.exe -ArgumentList '-NoProfile', '-ExecutionPolicy Bypass', '-File', '%~f0', '-Verb', 'RunAs'; exit }"

:: 콘솔 환경 설정
chcp 437 >nul
color 2A
cls
echo 환경을 초기화 중입니다...

:: 감사 구성 변수 설정
set "분류=계정 관리"
set "코드=W-37"
set "위험도=높음"
set "진단_항목=비밀번호 저장을 위한 복호화 가능한 암호화 사용"
set "진단_결과=양호"
set "현황="
set "대응방안=복호화 불가능한 암호화 방식 사용"

:: 디렉터리 설정
set "computerName=%COMPUTERNAME%"
set "rawDir=C:\Audit_%computerName%_Raw"
set "resultDir=C:\Audit_%computerName%_Results"

if exist "%rawDir%" rmdir /s /q "%rawDir%"
if exist "%resultDir%" rmdir /s /q "%resultDir%"
mkdir "%rawDir%"
mkdir "%resultDir%"

:: 보안 정책 및 시스템 정보 수집
PowerShell -Command "secedit /export /cfg '%rawDir%\Local_Security_Policy.txt' >nul"
PowerShell -Command "systeminfo > '%rawDir%\SystemInfo.txt'"
echo 로컬 보안 정책을 내보내고 시스템 정보를 수집했습니다.

:: Microsoft FTP 서비스 감사 실행
echo Microsoft FTP 서비스를 감사 중입니다...
PowerShell -Command "$ftpService = Get-Service -Name 'MSFTPSVC' -ErrorAction SilentlyContinue; if ($ftpService -and $ftpService.Status -eq 'Running') { 'W-37, 경고, Microsoft FTP 서비스가 실행 중이며, 이는 취약점이 될 수 있습니다.' | Out-File '%resultDir%\W-Window-%computerName%-Result.txt'; echo '경고: Microsoft FTP 서비스가 실행 중입니다. 필요하지 않은 경우 비활성화를 고려하세요.' } else { 'W-37, 안전, Microsoft FTP 서비스가 실행되지 않고 있습니다. 조치가 필요 없습니다.' | Out-File '%resultDir%\W-Window-%computerName%-Result.txt'; echo '안전: Microsoft FTP 서비스가 실행되지 않고 있습니다.' }"

:: 결과 CSV 파일로 저장
echo 분류,코드,위험도,진단_항목,진단_결과,현황,대응방안 > "%resultDir%\AuditResults.csv"
echo %분류%,%코드%,%위험도%,%진단_항목%,%진단_결과%,%현황%,%대응방안% >> "%resultDir%\AuditResults.csv"

echo 감사 완료. 결과는 %resultDir%\AuditResults.csv에서 확인하세요.
ENDLOCAL
pause
