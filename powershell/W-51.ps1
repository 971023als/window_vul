# JSON 데이터 초기화
$json = @{
    분류 = "계정관리"
    코드 = "W-51"
    위험도 = "상"
    진단 항목 = "Telnet 보안 설정"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "Telnet 보안 설정"
}

# 관리자 권한 요청
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "Start-Process PowerShell -ArgumentList '-ExecutionPolicy Bypass -File `"$PSCommandPath`"' -Verb RunAs"
    exit
}

# 콘솔 환경 설정
chcp 437 > $null
$Host.UI.RawUI.BackgroundColor = "DarkGreen"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

# 기본 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_$($computerName)_raw"
$resultDir = "C:\Window_$($computerName)_result"

# 디렉터리 준비
Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $rawDir, $resultDir -Force | Out-Null

# Telnet 서비스 보안 설정 검사
Write-Host "------------------------------------------Telnet Service Security Setting------------------------------------------"
$telnetServiceStatus = Get-Service -Name TlntSvr -ErrorAction SilentlyContinue

If ($telnetServiceStatus -and $telnetServiceStatus.Status -eq 'Running') {
    Try {
        $telnetConfig = & tlntadmn config
        $authenticationMethod = $telnetConfig | Where-Object {$_ -match "Authentication"}

        If ($authenticationMethod -match "NTLM" -and $authenticationMethod -notmatch "Password") {
            $json.진단 결과 = "양호"
            $json.현황 += "Telnet 서비스가 안전한 NTLM 인증 방식을 사용하고 있습니다."
        } Else {
            $json.진단 결과 = "취약"
            $json.현황 += "Telnet 서비스가 안전하지 않은 인증 방식을 사용하고 있습니다. NTLM을 사용하고 비밀번호를 피하도록 권장됩니다."
        }
    } Catch {
        $json.진단 결과 = "오류"
        $json.현황 += "Telnet 서비스 설정을 검색하는 데 실패했습니다."
    }
} Else {
    $json.현황 += "Telnet 서비스가 실행되지 않거나 설치되지 않았으며, 이는 안전으로 간주됩니다."
}

Write-Host "------------------------------------------End of Telnet Service Security Setting------------------------------------------"

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-51.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
Write-Host "진단 결과가 저장되었습니다: $jsonPath"

# 결과 요약 및 저장
Get-Content "$resultDir\W-51_${computerName}_diagnostic_results.json" | Out-File "$resultDir\security_audit_summary.txt"

# 정리 작업
Remove-Item -Path $rawDir\* -Force

Write-Host "Script has completed. Results have been saved to $resultDir\security_audit_summary.txt."
