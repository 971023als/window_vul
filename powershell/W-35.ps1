# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "ODBC_DSN_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-35"
$riskLevel = "중"
$diagnosisItem = "불필요한 ODBC/OLE-DB 데이터 소스 제거"
$remedialAction = "ODBC 데이터 원본 관리자(odbcad32.exe)에서 불필요한 시스템 DSN 제거"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] ODBC 데이터 소스 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직
try {
    # 시스템 DSN 레지스트리 경로 (64비트 및 32비트)
    $dsnPaths = @(
        "HKLM:\SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources",           # 64-bit
        "HKLM:\SOFTWARE\WOW6432Node\ODBC\ODBC.INI\ODBC Data Sources" # 32-bit
    )

    $foundDSNs = @()

    foreach ($path in $dsnPaths) {
        if (Test-Path $path) {
            $properties = Get-ItemProperty -Path $path
            $names = $properties.PSObject.Properties.Name | Where-Object { 
                $_ -notmatch "PSPath|PSParentPath|PSChildName|PSDrive|PSProvider" 
            }
            
            foreach ($name in $names) {
                $driver = $properties.$name
                $foundDSNs += [PSCustomObject]@{
                    Name = $name
                    Driver = $driver
                    Arch = if ($path -match "WOW6432Node") { "32-bit" } else { "64-bit" }
                }
            }
        }
    }

    # 4. 판정 로직
    if ($foundDSNs.Count -eq 0) {
        $result = "양호"
        $statusMsg = "등록된 시스템 DSN이 없습니다."
        $color = "Green"
    } else {
        # 샘플 데이터 소스 명칭 포함 여부 확인 (예: Sample, Northwind, AdventureWorks 등)
        $sampleDSNs = $foundDSNs | Where-Object { $_.Name -match "Sample|Test|Northwind|Adventure|Pubs" }
        
        $dsnSummary = $foundDSNs | ForEach-Object { "$($_.Name)($($_.Arch))" }
        $dsnString = $dsnSummary -join ", "

        if ($sampleDSNs) {
            $result = "취약"
            $statusMsg = "취약할 수 있는 샘플 또는 불필요한 DSN이 발견되었습니다: " + ($sampleDSNs.Name -join ", ")
            $color = "Red"
        } else {
            # 시스템에 DSN이 존재하므로 관리자가 '사용 여부'를 수동 확인하도록 유도 (상태 보고)
            $result = "수동 확인"
            $statusMsg = "시스템 DSN이 발견되었습니다. 현재 사용 중인지 확인이 필요합니다: $dsnString"
            $color = "Yellow"
        }
    }
} catch {
    $result = "오류"
    $statusMsg = "점검 중 에러 발생: $($_.Exception.Message)"
    $color = "Yellow"
}

# 5. 결과 객체 생성
$report = [PSCustomObject]@{
    "Category"       = $category
    "Code"           = $code
    "Risk Level"     = $riskLevel
    "Diagnosis Item" = $diagnosisItem
    "Result"         = $result
    "Current Status" = $statusMsg
    "Remedial Action"= $remedialAction
}

# 6. 콘솔 출력 및 CSV 저장
Write-Host "[결과] : $result" -ForegroundColor $color
Write-Host "[현황] : $statusMsg"
Write-Host "------------------------------------------------"

$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray