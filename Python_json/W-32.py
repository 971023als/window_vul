$json = @{
    분류 = "계정관리"
    코드 = "W-32"
    위험도 = "상"
    진단 항목 = "해독 가능한 암호화를 사용하여 암호 저장"
    진단 결과 = "양호"  # 기본 값을 "양호"로 가정
    현황 = @()
    대응방안 = "해독 가능한 암호화를 사용하여 암호 저장"
}

# 관리자 권한 확인 및 요청
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $script = "-File `"" + $MyInvocation.MyCommand.Path + "`""
    Start-Process PowerShell.exe -ArgumentList $script -Verb RunAs
    exit
}

# 초기 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"
Remove-Item -Path $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory

# 로컬 보안 정책 내보내기
secedit /export /cfg "$rawDir\Local_Security_Policy.txt" | Out-Null
New-Item -Path "$rawDir\compare.txt" -ItemType File

# 시스템 정보 저장
systeminfo | Out-File "$rawDir\systeminfo.txt"

# IIS 설정 분석
$applicationHostConfig = Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config"
$applicationHostConfig | Out-File "$rawDir\iis_setting.txt"
$bindingInfo = Select-String -Path "$rawDir\iis_setting.txt" -Pattern "physicalPath|bindingInformation"
$bindingInfo | Out-File "$rawDir\iis_path1.txt"

# W-32 디렉토리 권한 검사
If ((Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue).Status -eq "Running") {
    $directories = Get-Content "$rawDir\iis_path1.txt"
    foreach ($dir in $directories) {
        if (Test-Path $dir) {
            $acl = Get-Acl $dir
            $everyone = $acl.Access | Where-Object { $_.IdentityReference -eq "Everyone" }
            if ($everyone) {
                "위험: $dir 디렉토리에 Everyone 그룹에 대한 액세스 권한이 부여됨" | Out-File "$resultDir\W-Window-${computerName}-result.txt" -Append
                $json.현황 += "위험: $dir 디렉토리에 Everyone 그룹에 대한 액세스 권한이 부여됨"
            }
        }
    }
}

# JSON 결과를 파일에 저장
$jsonFilePath = "$resultDir\W-32.json"
$json | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFilePath
