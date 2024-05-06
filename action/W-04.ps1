# 운영 체제 버전 확인
$osVersion = (Get-WmiObject -Class Win32_OperatingSystem).Version

# NT 계열 운영 체제 버전
$ntVersions = @("4.0", "5.0", "5.1", "5.2", "6.0")

# NT 계열 확인
if ($ntVersions -contains $osVersion) {
    # 계정 잠금 임계값 설정
    $threshold = 5  # 최대 실패 허용 횟수

    # secedit를 사용하여 설정을 업데이트
    $secfilePath = "$env:TEMP\secfile.inf"
    $cfgPath = "$env:TEMP\cfgfile.inf"

    # 현재 설정 추출
    secedit /export /cfg $secfilePath

    # 설정 파일 읽기 및 수정
    (Get-Content $secfilePath) -replace "LockoutBadCount =.*", "LockoutBadCount = $threshold" | Set-Content $cfgPath

    # 설정 적용
    secedit /configure /db secedit.sdb /cfg $cfgPath

    Write-Host "계정 잠금 임계값이 설정되었습니다: $threshold 회"
} else {
    Write-Host "이 스크립트는 NT 계열 Windows에서만 실행됩니다. 현재 OS 버전: $osVersion"
}
