@echo off
setlocal enabledelayedexpansion

REM Set the directory containing the CSV files
set "csvDir=%~dp0result"

REM Define the output CSV file
set "mergedCSV=%csvDir%\Merged_Results.csv"

REM Create or clear the merged CSV file
if exist "!mergedCSV!" del "!mergedCSV!"
echo "Category,Code,Risk Level,Diagnosis Item,Result,Current Status,Remedial Action" > "!mergedCSV!"

REM Loop through all CSV files in the directory
for %%f in ("%csvDir%\*.csv") do (
    REM Skip the merged CSV in the loop
    if "%%f" neq "!mergedCSV!" (
        REM Skip the first line (header) of each CSV file
        for /f "skip=1 tokens=*" %%i in (%%f) do (
            echo %%i >> "!mergedCSV!"
        )
    )
)

echo Merged CSV created at: !mergedCSV!
endlocal
