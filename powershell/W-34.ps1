# 변수 초기화
$분류 = "계정 관리"
$코드 = "W-34"
$위험도 = "높음"
$진단_항목 = "비밀번호 저장을 위한 복호화 가능한 암호화 사용"
$진단_결과 = "양호"  # 기본 상태를 '양호'로 가정
$현황 = @()
$대응방안 = "비암호화 방식을 사용하여 비밀번호 저장을 방지하세요"

# 진단 결과 및 JSON 키 값 한국어로 설정
$auditParams = @{
    분류 = $분류
    코드 = $코드
    위험도 = $위험도
    진단_항목 = $진단_항목
    진단_결과 = $진단_결과
    현황 = $현황
    대응방안 = $대응방안
}

# 관리자 권한 요청
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "`"$PSCommandPath`"", "-Verb", "RunAs"
    exit
}

# 환경 설정 및 디렉터리 구성
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

function Initialize-Environment {
    Write-Host "환경을 설정하고 있습니다..."
    Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

    secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null
    New-Item -Path "$rawDir\compare.txt" -ItemType File | Out-Null

    systeminfo | Out-File -FilePath "$rawDir\systeminfo.txt"
}

# IIS 설정 분석 및 결과 업데이트
function Analyze-IISConfiguration {
    Write-Host "IIS 설정을 분석하고 있습니다..."
    $applicationHostConfig = Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
    $applicationHostConfig | Out-File -FilePath "$rawDir\iis_setting.txt"

    if ($applicationHostConfig -match "physicalPath|bindingInformation") {
        $auditParams.현황 += "암호화 설정에 문제가 있습니다."
        $auditParams.진단_결과 = "취약"
    } else {
        $auditParams.현황 += "암호화 설정이 양호합니다."
    }
}

# 스크립트 실행 단계
Initialize-Environment
Analyze-IISConfiguration

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-34.json"
$auditParams | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath

Write-Host "진단 결과가 저장되었습니다: $jsonFilePath"
