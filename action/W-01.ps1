$NewAdminName = "NewAdminAccountName"

# Administrator 계정 이름 변경
Rename-LocalUser -Name "Administrator" -NewName $NewAdminName

# 로컬 보안 정책 설정 변경을 확인
$secpol = secedit /export /cfg C:\secpol.cfg
(Get-Content C:\secpol.cfg).Replace('NewAdministratorName', $NewAdminName) | Set-Content C:\secpol.cfg
secedit /configure /db C:\secpol.sdb /cfg C:\secpol.cfg /quiet

# 로그 기록
Write-Host "Administrator 계정 이름이 변경되었습니다: $NewAdminName"
