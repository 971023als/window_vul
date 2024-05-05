@echo off
setlocal enabledelayedexpansion

REM Define the directory to store results and create if not exists
set "resultDir=%~dp0results"
if not exist "!resultDir!" mkdir "!resultDir!"

REM Define CSV file for scheduled tasks audit
set "csvFile=!resultDir!\Scheduled_Tasks_Audit.csv"
echo "Category,Code,Risk Level,Diagnosis Item,Service,Diagnosis Result,Status" > "!csvFile!"

REM Define security details
set "category=패치관리"
set "code=W-54"
set "riskLevel=상"
set "diagnosisItem=예약된 작업에 의심스러운 명령이 등록되어 있는지 점검"
set "service=Scheduled Tasks"
set "diagnosisResult=양호"
set "status="

set "TMP1=%~n0.log"
type nul > "!TMP1!"

echo ------------------------------------------------ >> "!TMP1!"
echo CODE [W-54] 예약된 작업에 의심스러운 명령 점검 >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

echo [양호]: 의심스러운 스케줄러 작업이 없습니다. >> "!TMP1!"
echo [경고]: 의심스러운 스케줄러 작업이 발견되었습니다. >> "!TMP1!"
echo ------------------------------------------------ >> "!TMP1!"

:: 스케줄러 작업 검사 (PowerShell 사용)
powershell -Command "& {
    $schedulerTasks = schtasks /query /fo CSV | ConvertFrom-Csv;
    if ($schedulerTasks) {
        $suspiciousTasks = $schedulerTasks | Where-Object { $_.TaskName -like '*admin*' -or $_.TaskName -like '*hack*' }
        if ($suspiciousTasks) {
            $status = 'WARN: 의심스러운 스케줄러 작업이 발견되었습니다: ' + ($suspiciousTasks.TaskName -join ', ')
        } else {
            $status = 'OK: 의심스러운 스케줄러 작업이 없으며, 시스템은 안전합니다.'
        }
    } else {
        $status = 'OK: 스케줄러에 예약된 작업이 없으며, 이는 보안 상태가 안전함을 나타냅니다.'
    }
    \"$status\" | Out-File -FilePath temp.txt;
}"
set /p diagnosisResult=<temp.txt
del temp.txt

REM Save results to CSV
echo "!category!","!code!","!riskLevel!","!diagnosisItem!","!service!","!diagnosisResult!","!status!" >> "!csvFile!"

echo ------------------------------------------------ >> "!TMP1!"
type "!TMP1!"

echo 감사 완료. 결과는 %resultDir%\Scheduled_Tasks_Audit.csv에서 확인하세요.
echo.

endlocal
pause
