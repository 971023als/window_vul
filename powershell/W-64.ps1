# JSON 데이터 초기화
$json = @{
    분류 = "보안관리"
    코드 = "W-64"
    위험도 = "상"
    진단 항목 = "화면보호기설정"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "화면보호기설정 조정"
}

# 관리자 권한으로 스크립트 실행 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$computerName = $env:COMPUTERNAME
$rawDirectory = "C:\Windows_Security_Audit\$computerName`_raw"
$resultDirectory = "C:\Windows_Security_Audit\$computerName`_result"

# 기존 정보 삭제 및 새 디렉터리 생성
Remove-Item -Path $rawDirectory, $resultDirectory -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDirectory, $resultDirectory -Force | Out-Null

# 스크린 세이버 정책 확인
$screenSaveActive = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop").ScreenSaveActive
$screenSaverIsSecure = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop").ScreenSaverIsSecure
$screenSaveTimeOut = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop").ScreenSaveTimeOut

If ($screenSaveActive -eq "1") {
    If ($screenSaverIsSecure -eq "1") {
        If ($screenSaveTimeOut -lt 600) {
            $json.진단 결과 = "취약"
            $json.현황 += "스크린 세이버가 활성화되었으나, 타임아웃 시간이 10분 미만으로 설정되어 있습니다."
        } else {
            $json.현황 += "스크린 세이버가 적절히 설정되어 있습니다."
        }
    } else {
        $json.진단 결과 = "취약"
        $json.현황 += "안전한 로그온이 요구되지 않는 스크린 세이버가 설정되어 있습니다."
    }
} else {
    $json.진단 결과 = "취약"
    $json.현황 += "스크린 세이버가 비활성화되어 있습니다."
}

# JSON 데이터를 파일로 저장
$jsonPath = "$resultDirectory\W-64_${computerName}_diagnostic_results.json"
$json | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# 결과 출력
Write-Host "Results have been saved to $resultDirectory 폴더에 저장되었습니다."
Write-Host "스크립트를 종료합니다."
