# 변수 설정
$webDirectory = "C:\Users\User\Documents"
$now = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$resultsPath = Join-Path $webDirectory "results_$now.json"
$errorsPath = Join-Path $webDirectory "errors_$now.log"
$csvPath = Join-Path $webDirectory "results_$now.csv"

# 로깅 설정
function Write-Log {
    Param ([string]$message)
    Add-Content -Path "$webDirectory\security_checks.log" -Value "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"): $message"
}

# Excel 데이터 읽기
function Read-DiagnosticData {
    Param ([string]$filePath)
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $workbook = $excel.Workbooks.Open($filePath)
    $sheet = $workbook.Sheets.Item(1)
    $diagnostics = @()
    $startRow = 8
    Do {
        $row = $sheet.Rows.Item($startRow)
        if ($null -ne $row.Cells.Item(1).Value()) {
            $area = $row.Cells.Item(1).Text
        }
        if ($null -ne $row.Cells.Item(4).Value()) {
            $diagnostic = @{
                "Category" = $area
                "Code" = $row.Cells.Item(4).Text
                "RiskLevel" = $row.Cells.Item(2).Text
                "Item" = $row.Cells.Item(3).Text
                "Result" = $row.Cells.Item(6).Text
                "Output" = ""
            }
            $diagnostics += $diagnostic
        }
        $startRow++
    } While ($null -ne $row.Cells.Item(1).Value())
    $excel.Quit()
    return $diagnostics
}

# 보안 점검 실행
function Execute-SecurityChecks {
    Write-Log "보안 점검 스크립트 실행"
    $diagnostics = Read-DiagnosticData -filePath "path_to_your_excel_file.xlsx"
    $errors = @()
    foreach ($diagnostic in $diagnostics) {
        $scriptPath = Join-Path $webDirectory ($diagnostic.Code + ".py")
        if (Test-Path $scriptPath) {
            try {
                $output = & python $scriptPath
                $diagnostic.Output = $output
            } catch {
                $error = "$($diagnostic.Code): $_"
                $errors += $error
                Write-Log $error
            }
        }
    }
    $diagnostics | ConvertTo-Json | Out-File $resultsPath
    $errors | Out-File $errorsPath
    $diagnostics | Export-Csv -Path $csvPath -NoTypeInformation
}

# 메인 실행
Execute-SecurityChecks
