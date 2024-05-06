# 운영 체제 버전 확인
$osVersion = (Get-WmiObject -Class Win32_OperatingSystem).Version

# NT 계열 운영 체제 버전
$ntVersions = @("4.0", "5.0", "5.1", "5.2", "6.0")

# NT 계열인지 확인
if ($ntVersions -contains $osVersion) {
    # 사용자 계정 목록 불러오기
    $users = Get-LocalUser

    # 삭제하려는 계정의 이름을 배열로 설정
    $unnecessaryAccounts = @("exampleUser1", "exampleUser2")  # 수정 필요

    # 불필요한 계정 찾아서 처리
    foreach ($user in $users) {
        if ($user.Name -in $unnecessaryAccounts) {
            # 계정 비활성화 (삭제 대신 비활성화를 원하는 경우 이 줄의 주석을 해제하고 다음 줄을 주석 처리하세요)
            # Disable-LocalUser -Name $user.Name

            # 계정 삭제
            Remove-LocalUser -Name $user.Name
            Write-Host "계정이 삭제되었습니다: $($user.Name)"
        }
    }
} else {
    Write-Host "이 스크립트는 NT 계열 Windows에서만 실행됩니다. 현재 OS 버전: $osVersion"
}
