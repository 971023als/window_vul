# 필요한 모듈 설치
Install-Module -Name ImportExcel -Scope CurrentUser -Force

# 컴퓨터 이름 변수 설정
$computerName = $env:COMPUTERNAME

# 결과 파일이 저장될 디렉토리 설정
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 최종 Excel 파일 경로
$excelFilePath = "C:\Window_${computerName}_result\Summary.xlsx"

# Excel 파일 생성 준비
$excelPackage = New-ExcelPackage

# JSON 파일을 읽고 Excel로 변환
1..72 | ForEach-Object {
    $jsonFile = Join-Path -Path $resultDir -ChildPath ("W-$("{0:D2}" -f $_).json")
    if (Test-Path $jsonFile) {
        $jsonData = Get-Content -Path $jsonFile | ConvertFrom-Json
        $sheetName = "W-$("{0:D2}" -f $_)"
        $jsonData | Export-Excel -ExcelPackage $excelPackage -WorksheetName $sheetName -AutoSize
    } else {
        Write-Host "파일이 존재하지 않습니다: $jsonFile"
    }
}

# Excel 파일 저장
$excelPackage.SaveAs($excelFilePath)
Write-Host "Excel 파일이 생성되었습니다: $excelFilePath"
