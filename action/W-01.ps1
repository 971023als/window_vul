# 새 계정 이름을 설정하세요. 예: NewAdminName
$newName = "NewAdminName"

# 기본 Administrator 계정 이름 가져오기
$defaultAdminName = (Get-WmiObject Win32_UserAccount -Filter "LocalAccount=True AND SID LIKE 'S-1-5-21-%-500'").Name

# 계정 이름 변경
Rename-LocalUser -Name $defaultAdminName -NewName $newName

# 변경 사항 확인
Get-LocalUser -Name $newName | Format-List *
