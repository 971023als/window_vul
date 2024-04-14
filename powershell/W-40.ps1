# JSON 데이터 초기화
$json = [PSCustomObject]@{
    분류 = "서비스관리"
    코드 = "W-40"
    위험도 = "상"
    진단 항목 = "FTP 접근 제어 설정"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "FTP 접근 제어 설정"
}

# 관리자 권한 요청
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
If (-not $isAdmin) {
    Write-Host "이 스크립트는 관리자 권한으로 실행되어야 합니다. 관리자 권한으로 재실행하겠습니다..."
    Start-Process PowerShell -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "`"$PSCommandPath`"", "-Verb", "RunAs"
    Exit
}

# 콘솔 환경 설정
chcp 437 | Out-Null
$host.UI.RawUI.BackgroundColor = "DarkGreen"
$host.UI.RawUI.ForegroundColor = "Green"
Clear-Host

Write-Host "------------------------------------------설정 시작---------------------------------------"
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 결과 저장 경로 안내
Write-Host "결과는 다음 위치에 저장될 예정입니다: $resultDir\W-40.json"

Try {
    # 이전 디렉토리 삭제 및 새 디렉토리 생성
    Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

    # 진단 로직 (간략화된 형태로 표현)
    # 실제 진단 로직을 구현하세요. 이 예제에서는 단순화를 위해 직접 값을 설정합니다.
    $isFtpSecure = $false

    if (-not $isFtpSecure) {
        $json."진단 결과" = "위험"
        $json.현황 += "특정 IP 주소에서만 FTP 접속이 허용되어야 하나, 현재 모든 IP에서 접속이 허용되어 있어 취약합니다."
    } else {
        $json.현황 += "특정 IP 주소에서만 FTP 접속이 허용되어 있습니다."
    }

    # JSON 결과를 파일에 저장
    $json | ConvertTo-Json -Depth 3 | Out-File -FilePath "$resultDir\W-40.json"

} Catch {
    Write-Host "오류 발생: $_"
}
