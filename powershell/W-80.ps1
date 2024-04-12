json = {
        "분류": "보안관리",
        "코드": "W-80",
        "위험도": "상",
        "진단 항목": "컴퓨터 계정 암호 최대 사용 기간",
        "진단 결과": "양호",  # 기본 값을 "양호"로 가정
        "현황": [],
        "대응방안": "컴퓨터 계정 암호 최대 사용 기간"
    }

# 관리자 권한으로 스크립트 실행 확인
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Start-Process PowerShell -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", "$PSCommandPath", "-Verb", "RunAs"
    exit
}

# 변수 설정
$computerName = $env:COMPUTERNAME
$rawDir = "C:\Window_${computerName}_raw"
$resultDir = "C:\Window_${computerName}_result"

# 디렉터리 생성 및 초기화
Remove-Item $rawDir, $resultDir -Recurse -ErrorAction SilentlyContinue
New-Item -Path $rawDir, $resultDir -ItemType Directory

# 로컬 보안 정책 및 시스템 정보 내보내기
secedit /export /cfg "$rawDir\Local_Security_Policy.txt"
systeminfo | Out-File "$rawDir\systeminfo.txt"

# IIS 설정 분석
Get-Content "$env:WinDir\System32\Inetsrv\Config\applicationHost.Config" |
    Select-String "physicalPath|bindingInformation" |
    Out-File "$rawDir\iis_setting.txt"

# 보안 정책 분석 예시 (W-80)
$maximumPasswordAge = (Get-Content "$rawDir\Local_Security_Policy.txt" | Select-String "MaximumPasswordAge").ToString().Split('=')[1].Trim()
$disablePasswordChange = (Get-Content "$rawDir\Local_Security_Policy.txt" | Select-String "disablepasswordchange").ToString().Split('=')[1].Trim()

If ($maximumPasswordAge -lt 90 -and $disablePasswordChange -eq "0")
{
    "W-80,O,|" | Out-File "$resultDir\W-Window-$computerName-result.txt" -Append
    # 추가 결과 처리
}
Else
{
    "W-80,X,|" | Out-File "$resultDir\W-Window-$computerName-result.txt" -Append
    # 추가 결과 처리
}

# 결과 요약 및 저장
Get-Content "$resultDir\W-Window-*" | Out-File "$resultDir\security_audit_summary.txt"

# 정리 작업
Remove-Item "$rawDir\*" -Force
