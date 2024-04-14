# Initial Setup
$json = @{
    분류 = "계정관리"
    코드 = "W-33"
    위험도 = "상"
    진단 항목 = "해독 가능한 암호화를 사용하여 암호 저장"
    진단 결과 = "양호"  # Presuming "Good" as the default value
    현황 = @()
    대응방안 = "Implement encryption that cannot be decrypted to store passwords"
}

# Check and Request Administrator Privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "`"$PSCommandPath`"", "-Verb", "RunAs"
    exit
}

$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# Prepare Environment
function Prepare-Environment {
    Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

    secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null
    New-Item -Path "$rawDir\compare.txt" -ItemType File -Value $null

    Get-Location.Path | Out-File -FilePath "$rawDir\install_path.txt"
    systeminfo | Out-File -FilePath "$rawDir\systeminfo.txt"
}

# IIS Configuration Analysis
function Analyze-IISConfiguration {
    $applicationHostConfigPath = "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
    $applicationHostConfig = Get-Content $applicationHostConfigPath
    $applicationHostConfig | Out-File "$rawDir\iis_setting.txt"

    $unsupportedExtensions = @(".htr", ".idc", ".stm", ".shtm", ".shtml", ".printer", ".htw", ".ida", ".idq")
    $foundExtensions = $applicationHostConfig | Where-Object { $_ -match ($unsupportedExtensions -join "|") }

    if ($foundExtensions) {
        $json.현황 += "Unsupported extensions found posing a security risk."
        $json.진단 결과 = "취약"
        $foundExtensions | Out-File "$resultDir\W-Window-$computerName.txt"
    } else {
        $json.현황 += "No unsupported extensions found, complying with security standards."
    }
}

# Execute
Prepare-Environment
Analyze-IISConfiguration

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-33.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
