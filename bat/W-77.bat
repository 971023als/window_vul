@echo off
SETLOCAL EnableDelayedExpansion

:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    PowerShell -Command "Start-Process cmd.exe -ArgumentList '/c %~f0' -Verb RunAs"
    exit
)

:: Variables
set "category=보안관리"
set "code=W-77"
set "riskLevel=상"
set "diagnosticItem=LAN Manager 인증 수준"
set "diagnosticResult=양호"
set "status=점검 시작..."
set "countermeasure=LAN Manager 인증 수준 변경"
set "computerName=%COMPUTERNAME%"
set "resultDir=C:\Window_%computerName%_result"

:: Setup environment
if not exist "%resultDir%" mkdir "%resultDir%"
echo Environment setup complete.

:: Perform the diagnostic check
echo Checking LAN Manager authentication level...
for /f "tokens=2*" %%a in ('reg query HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v LmCompatibilityLevel 2^>nul') do set lmLevel=%%b

:: Determine status based on the retrieved value
if defined lmLevel (
    if %lmLevel% geq 3 (
        set "status=LAN Manager 인증 수준이 보안에 적합하게 설정되어 있습니다."
    ) else (
        set "diagnosticResult=취약"
        set "status=LAN Manager 인증 수준이 보안 기준에 미치지 못합니다."
    )
) else (
    set "diagnosticResult=오류"
    set "status=LAN Manager 인증 수준을 확인할 수 없습니다."
)

:: Save results to a CSV file
echo 분류,코드,위험도,진단 항목,진단 결과,현황,대응방안 > "%resultDir%\%code%.csv"
echo %category%,%code%,%riskLevel%,%diagnosticItem%,%diagnosticResult%,%status%,%countermeasure% >> "%resultDir%\%code%.csv"

echo Diagnostic results have been saved: %resultDir%\%code%.csv
echo Script has completed.
pause
ENDLOCAL
