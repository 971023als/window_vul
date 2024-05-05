@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for FTP directory access audit
set "csvFile=!resultDir!\FTP_Directory_Access_Audit.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define audit details
set "category=서비스 관리"
set "code=W-38"
set "riskLevel=상"
set "diagnosisItem=FTP 디렉토리 접근권한 설정"
set "service=FTP"
set "diagnosisResult=양호"
set "status="
set "mitigation=적절한 접근권한 설정"

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-38] FTP 디렉토리 접근권한 감사 실행 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 적절한 접근 권한이 설정되어 있는 경우 >> "!TMP1!"
echo [취약]: EVERYONE 그룹에 FullControl 접근 권한이 있는 경우 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: FTP 디렉토리 접근권한 검사 (PowerShell 사용)
powershell -Command "& {
    $isSecure = $true
    If (Test-Path '%rawDir%\FTP_PATH.txt') {
        Get-Content '%rawDir%\FTP_PATH.txt' | ForEach-Object {
            $filePath = $_
            $acl = Get-Acl $filePath
            $hasFullControl = $acl.Access | Where-Object {
                $_.FileSystemRights -match 'FullControl' -and $_.IdentityReference -eq 'Everyone'
            }
            if ($hasFullControl) {
                $isSecure = $false
            }
        }
    }
    if (!$isSecure) {
        $status = 'WARN: EVERYONE 그룹에 대한 FullControl 접근 권한이 발견되어 취약합니다.'
    } else {
        $status = 'OK: FTP 디렉토리 접근권한이 적절히 설정됨.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p status=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!","!mitigation!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\FTP_Directory_Access_Audit.csv에서 확인하세요.
echo.

endlocal
pause
