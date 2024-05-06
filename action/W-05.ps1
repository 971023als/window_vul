# 운영 체제 버전 확인
$osVersion = (Get-WmiObject -Class Win32_OperatingSystem).Version

# NT 계열 운영 체제 버전
$ntVersions = @("4.0", "5.0", "5.1", "5.2", "6.0")

# NT 계열인지 확인
if ($ntVersions -contains $osVersion) {
    # "해독 가능한 암호화를 사용하여 암호 저장" 정책 설정
    $policyName = "ClearTextPassword"
    $policyValue = 0  # 0은 '사용 안 함', 1은 '사용'

    # secedit를 사용하여 설정을 업데이트
    $secfilePath = "$env:TEMP\secfile.inf"
    $cfgPath = "$env:TEMP\cfgfile.inf"

    # 현재 설정 추출
    secedit /export /cfg $secfilePath

    # 설정 파일 읽기 및 수정
    (Get-Content $secfilePath) -replace "$policyName =.*", "$policyName = $policyValue" | Set-Content $cfgPath

    # 설정 적용
    secedit /configure /db secedit.sdb /cfg $cfgPath

    Write-Host "정책 '$policyName'이 '사용 안 함'으로 설정되었습니다."
} else {
    Write-Host "이 스크립트는 NT 계열 Windows에서만 실행됩니다. 현재 OS 버전: $osVersion"
}
