# JSON 데이터 초기화
$json = @{
    분류 = "서비스관리"
    코드 = "W-45"
    위험도 = "상"
    진단 항목 = "IIS 웹서비스 정보 숨김"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "IIS 웹서비스 정보 숨김"
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

# IIS 커스텀 에러 페이지 설정 검사 시작
Write-Host "------------------------------------------W-45 IIS 커스텀 에러 페이지 설정 검사 시작------------------------------------------"
$webService = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
if ($webService.Status -eq "Running") {
    # Sample Path for illustration
    $webConfigPath = "C:\inetpub\wwwroot\web.config"
    
    if (Test-Path $webConfigPath) {
        $webConfigContent = Get-Content $webConfigPath
        $custErrPath = $webConfigContent | Select-String -Pattern "customErrors mode=`"On`""

        if ($custErrPath) {
            $json.현황 += "IIS 커스텀 에러 페이지 설정이 적절하게 구성되어 보안이 강화되었습니다."
        } else {
            $json."진단 결과" = "취약"
            $json.현황 += "IIS 커스텀 에러 페이지 설정이 적절하지 않아 보안에 취약할 수 있습니다."
        }
    } else {
        $json.현황 += "web.config 파일을 찾을 수 없습니다."
    }
} else {
    $json."진단 결과" = "정보"
    $json.현황 += "World Wide Web Publishing Service가 실행되지 않고 있습니다. IIS 설정이 필요 없을 수 있습니다."
}
Write-Host "-------------------------------------------W-45 IIS 커스텀 에러 페이지 설정 검사 종료------------------------------------------"

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-45.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"

# 정리 작업
Write-Host "정리 작업을 수행합니다..."
Remove-Item "$rawDir\*" -Force

Write-Host "스크립트를 종료합니다."
