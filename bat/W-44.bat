@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for RDP encryption level audit
set "csvFile=!resultDir!\RDP_Encryption_Level_Audit.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define audit details
set "category=서비스관리"
set "code=W-44"
set "riskLevel=상"
set "diagnosisItem=터미널 서비스 암호화 수준 설정"
set "service=RDP"
set "diagnosisResult=양호"
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-44] 터미널 서비스 암호화 수준 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: RDP 최소 암호화 수준이 적절히 설정되어 있습니다. >> "!TMP1!"
echo [취약]: RDP 최소 암호화 수준이 낮게 설정되어 있습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: RDP 최소 암호화 수준 검사 (PowerShell 사용)
powershell -Command "& {
    $regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
    $minEncryptionLevel = (Get-ItemProperty -Path $regPath -Name 'MinEncryptionLevel' -ErrorAction SilentlyContinue).MinEncryptionLevel

    if ($minEncryptionLevel -and $minEncryptionLevel -gt 1) {
        $status = 'OK: RDP 최소 암호화 수준이 적절히 설정되어 있습니다.'
    } else {
        $status = 'WARN: RDP 최소 암호화 수준이 낮게 설정되어 있어 보안에 취약할 수 있습니다.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p status=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\RDP_Encryption_Level_Audit.csv에서 확인하세요.
echo.

endlocal
pause
