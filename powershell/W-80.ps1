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
    Write-Host "Re-running the script with administrator privileges."
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
            "All conditions met, no security policy issues." | Out-File "$resultDir\W-Window-$computerName-result.txt"
        } else {
            "Conditions not met, security policy review needed." | Out-File "$resultDir\W-Window-$computerName-result.txt"
        }
    } catch {
        "Failed to parse security settings, please check the Local_Security_Policy.txt file format." | Out-File "$resultDir\W-Window-$computerName-result.txt"
    }
}

$jsonFilePath = "$resultDir\W-80.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath

Get-Content "$resultDir\W-Window-*" | Out-File "$resultDir\security_audit_summary.txt"

Remove-Item "$rawDir\*" -Force
Write-Host "The script has completed."
