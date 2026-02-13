# 1. 초기 설정 및 결과 폴더 생성
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultDir = Join-Path $scriptPath "result"
if (-not (Test-Path $resultDir)) { New-Item -ItemType Directory -Path $resultDir | Out-Null }

$csvFile = Join-Path $resultDir "NetBIOS_Binding_Check.csv"

# 2. 진단 정보 기본 설정
$category = "서비스 관리"
$code = "W-20"
$riskLevel = "상"
$diagnosisItem = "NetBIOS 바인딩 서비스 구동 점검"
$remedialAction = "모든 네트워크 어댑터에서 'NetBIOS over TCP/IP'를 '비활성화'로 설정"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "CODE [$code] NetBIOS 바인딩 점검 시작" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# 3. 실제 점검 로직 (WMI/CIM을 사용하여 어댑터 설정 확인)
try {
    # IP가 할당된 활성 네트워크 어댑터 구성 정보 가져오기
    $adapters = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
    
    $vulnerableAdapters = @()
    $totalAdapters = 0

    foreach ($adapter in $adapters) {
        $totalAdapters++
        # TcpipNetbiosOptions 값 확인
        # 0: DHCP 서버 설정 사용 (Default)
        # 1: NetBIOS over TCP/IP 활성화 (Enable)
        # 2: NetBIOS over TCP/IP 비활성화 (Disable)
        
        if ($adapter.TcpipNetbiosOptions -ne 2) {
            $statusStr = switch ($adapter.TcpipNetbiosOptions) {
                0 { "DHCP 설정 따름(기본값)" }
                1 { "활성화됨" }
                Default { "알 수 없음" }
            }
            $vulnerableAdapters += "$($adapter.Description) (상태: $statusStr)"
        }
    }

    # 4. 판정 로직
    if ($vulnerableAdapters.Count -gt 0) {
        $result = "취약"
        $status = "다음 어댑터에서 NetBIOS over TCP/IP가 활성화되어 있습니다: " + ($vulnerableAdapters -join ", ")
        $color = "Red"
    } else {
        $result = "양호"
        $status = "모든 활성 네트워크 어댑터($totalAdapters개)에서 NetBIOS over TCP/IP가 비활성화되어 있습니다."
        $color = "Green"
    }
} catch {
    $result = "오류"
    $status = "네트워크 어댑터 정보를 가져오는 중 에러 발생: $($_.Exception.Message)"
    $color = "Yellow"
}

# 5. 결과 객체 생성
$report = [PSCustomObject]@{
    "Category"       = $category
    "Code"           = $code
    "Risk Level"     = $riskLevel
    "Diagnosis Item" = $diagnosisItem
    "Result"         = $result
    "Current Status" = $status
    "Remedial Action"= $remedialAction
}

# 6. 콘솔 출력 및 CSV 저장
Write-Host "[결과] : $result" -ForegroundColor $color
Write-Host "[현황] : $status"
Write-Host "------------------------------------------------"

# CSV 저장 (Append 모드)
$report | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8 -Append

Write-Host "`n점검 완료! 결과가 저장되었습니다: $csvFile" -ForegroundColor Gray