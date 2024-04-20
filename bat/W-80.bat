$json = @{
    "분류" = "보안관리"
    "코드" = "W-80"
    "위험도" = "상"
    "진단 항목" = "컴퓨터 계정 암호 최대 사용 기간"
    "진단 결과" = "양호"
    "현황" = @()
    "대응방안" = "컴퓨터 계정 암호 최대 사용 기간"
}

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "관리자 권한으로 스크립트를 다시 실행합니다."
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", $PSCommandPath -Verb RunAs
    Exit
}

$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
systeminfo | Out-File "$rawDir\systeminfo.txt"

$iisConfigPath = "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
if (Test-Path $iisConfigPath) {
    Get-Content $iisConfigPath | Select-String "physicalPath|bindingInformation" | Out-File "$rawDir\iis_setting.txt"
}

if (Test-Path "$rawDir\Local_Security_Policy.txt") {
    $policyContent = Get-Content "$rawDir\Local_Security_Policy.txt"
    try {
        $maximumPasswordAge = ($policyContent | Select-String "MaximumPasswordAge").ToString().Split('=')[1].Trim()
        $disablePasswordChange = ($policyContent | Select-String "disablepasswordchange").ToString().Split('=')[1].Trim()

        if ($maximumPasswordAge -lt 90 -and $disablePasswordChange -eq "0") {
            "모든 조건이 충족되었습니다. 보안 정책 문제가 없습니다." | Out-File "$resultDir\W-Window-$computerName-result.txt"
        } else {
            "조건이 충족되지 않았습니다. 보안 정책 검토가 필요합니다." | Out-File "$resultDir\W-Window-$computerName-result.txt"
        }
    } catch {
        "보안 설정을 분석하지 못했습니다. Local_Security_Policy.txt 파일 형식을 확인하세요." | Out-File "$resultDir\W-Window-$computerName-result.txt"
    }
}

$jsonFilePath = "$resultDir\W-80.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath

Get-Content "$resultDir\W-Window-*" | Out-File "$resultDir\security_audit_summary.txt"

Remove-Item "$rawDir\*" -Force
Write-Host "스크립트가 완료되었습니다."
