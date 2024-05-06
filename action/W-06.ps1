# 운영 체제 버전 확인
$osVersion = (Get-WmiObject -Class Win32_OperatingSystem).Version

# NT 계열 운영 체제 버전
$ntVersions = @("4.0", "5.0", "5.1", "5.2", "6.0")

# NT 계열인지 확인
if ($ntVersions -contains $osVersion) {
    # 불필요한 계정 이름을 배열로 설정
    $unnecessaryAdmins = @("unnecessaryUser1", "unnecessaryUser2")  # 실제 계정 이름으로 수정 필요

    # Administrators 그룹에서 계정 제거
    foreach ($user in $unnecessaryAdmins) {
        try {
            Remove-LocalGroupMember -Group "Administrators" -Member $user -ErrorAction Stop
            Write-Host "계정이 Administrators 그룹에서 제거되었습니다: $user"
        } catch {
            Write-Host "오류: 계정 제거 중 문제가 발생했습니다. 계정: $user"
        }
    }
} else {
    Write-Host "이 스크립트는 NT 계열 Windows에서만 실행됩니다. 현재 OS 버전: $osVersion"
}
