# 초기 설정
$webDirectory = "C:\www\html"
$now = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$resultsPath = Join-Path $webDirectory "results_$now.json"
$errorsPath = Join-Path $webDirectory "errors_$now.log"
$csvPath = Join-Path $webDirectory "results_$now.csv"
$htmlPath = Join-Path $webDirectory "index.html"

function Execute-SecurityChecks {
    Write-Host "보안 점검 스크립트 실행"
    $errors = @()
    $results = @()
    # 예시: Python 스크립트 실행
    1..72 | ForEach-Object {
        $scriptPath = "W-$("{0:D2}" -f $_).py"
        if (Test-Path $scriptPath) {
            try {
                $result = python $scriptPath
                $results += $result
            } catch {
                $errors += $_.Exception.Message
            }
        } else {
            $errors += "$scriptPath not found"
        }
    }
    $results | ConvertTo-Json | Set-Content $resultsPath
    $errors | Set-Content $errorsPath
}

function Convert-Results {
    Write-Host "결과 변환"
    $data = Get-Content $resultsPath | ConvertFrom-Json
    if ($data) {
        # CSV 변환
        $data | Export-Csv $csvPath -NoTypeInformation -Encoding UTF8

        # HTML 변환
        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Security Check Results</title>
    <style>
        table {
            width: 100%; border-collapse: collapse;
        }
        th, td {
            border: 1px solid black; padding: 8px;
        }
        th {
            background-color: #4CAF50; color: white;
        }
    </style>
</head>
<body>
    <h1>Security Check Results</h1>
    <table>
        <tr><th>$(($data[0].PSObject.Properties.Name -join "</th><th>"))</th></tr>
$(foreach ($item in $data) {
    "<tr><td>$($item.PSObject.Properties.Value -join "</td><td>")</td></tr>"
})
    </table>
</body>
</html>
"@
        $htmlContent | Set-Content $htmlPath
    }
}

function Main {
    Execute-SecurityChecks
    Convert-Results
}

Main
