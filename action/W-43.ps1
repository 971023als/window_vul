# JSON 데이터 초기화
$json = @{
    분류 = "서비스관리"
    코드 = "W-43"
    위험도 = "상"
    진단 항목 = "최신 서비스팩 적용"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "최신 서비스팩 적용"
}

# 관리자 권한 요청
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process PowerShell -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", $PSCommandPath, "-Verb", "RunAs"
    exit
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

# 이전 디렉토리 삭제 및 새 디렉토리 생성
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

# OS 버전 및 서비스팩 진단 시작
Write-Host "------------------------------------------W-43 OS 버전 및 서비스팩 진단 시작------------------------------------------"
Try {
    $osInfo = Get-CimInstance Win32_OperatingSystem
    $osVersion = $osInfo.Version
    $servicePack = $osInfo.ServicePackMajorVersion

    if ($servicePack -eq 0) {
        $json.진단 결과 = "취약"
        $json.현황 += "최신 서비스팩이 적용되지 않았습니다."
    } else {
        $json.현황 += "최신 서비스팩이 적용되어 있습니다."
    }
}
Catch {
    $json.진단 결과 = "오류"
    $json.현황 += "OS 버전 및 서비스팩 진단 중 오류가 발생했습니다."
    Write-Host "오류: $_"
}

Write-Host "-------------------------------------------진단 종료------------------------------------------"

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-43.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath

Write-Host "결과가 저장되었습니다: $jsonFilePath"

# 정리 작업
Write-Host "정리 작업을 수행합니다..."
Remove-Item "$rawDir\*" -Force

Write-Host "스크립트를 종료합니다."
