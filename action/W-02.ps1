# 운영 체제 버전 확인
$osVersion = (Get-WmiObject -Class Win32_OperatingSystem).Version

# NT 계열 운영 체제 버전
$ntVersions = @("4.0", "5.0", "5.1", "5.2", "6.0")

# Guest 계정 이름 가져오기
$guestAccount = Get-LocalUser -Name "Guest" -ErrorAction SilentlyContinue

# NT 계열 확인 및 Guest 계정 비활성화
if ($guestAccount -and $ntVersions -contains $osVersion) {
    # Guest 계정이 활성화 되어 있는지 확인
    if ($guestAccount.Enabled) {
        # Guest 계정 비활성화
        Disable-LocalUser -Name "Guest"
        Write-Host "Guest 계정이 비활성화 되었습니다."
    } else {
        Write-Host "Guest 계정은 이미 비활성화 상태입니다."
    }
} else {
    Write-Host "이 스크립트는 NT 계열 Windows에서만 실행됩니다. 현재 OS 버전: $osVersion"
}

# 변경 사항 확인
if ($guestAccount) {
    Get-LocalUser -Name "Guest" | Format-List *
} else {
    Write-Host "Guest 계정을 찾을 수 없습니다."
}
