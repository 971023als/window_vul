$json = @{
    "분류" = "보안관리"
    "코드" = "W-81"
    "위험도" = "상"
    "진단 항목" = "시작프로그램 목록 분석"
    "진단 결과" = "양호"
    "현황" = @()
    "대응방안" = "시작프로그램 목록을 정기적으로 검토하고, 불필요한 프로그램은 제거"
}

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "$PSCommandPath", "-Verb", "RunAs"
    Exit
}

$computerName = $env:COMPUTERNAME
$resultDir = "C:\Window_${computerName}_result"

if (-not (Test-Path $resultDir)) {
    New-Item -Path $resultDir -ItemType Directory | Out-Null
}

# Analyze Startup Programs
$startupPrograms = Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location, User
foreach ($program in $startupPrograms) {
    $program | Add-Member -NotePropertyName "Status" -NotePropertyValue "Reviewed"
    $json.현황 += $program.PSObject.Properties.Value | Out-String
}

# Save JSON results
$jsonFilePath = "$resultDir\W-81.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath

# Output results to a text file for audit
$startupPrograms | Format-Table | Out-File "$resultDir\W-81-${computerName}-startup-analysis.txt"

Write-Host "스크립트 실행 완료. 결과는 $resultDir 에 저장되었습니다."
