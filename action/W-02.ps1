function Disable-GuestAccount {
    param (
        [string] $ComputerName = $env:COMPUTERNAME  # 기본값은 로컬 컴퓨터
    )
    try {
        # 로컬 또는 원격 컴퓨터의 게스트 계정 객체 가져오기
        $guestAccount = Get-LocalUser -Name "Guest" -ComputerName $ComputerName
        
        # 계정 비활성화
        $guestAccount | Disable-LocalUser -ComputerName $ComputerName

        # 결과 로깅
        Write-Output "Guest account on $ComputerName has been disabled successfully."
    } catch {
        Write-Output "Error disabling guest account on $ComputerName: $_"
    }
}

# 로컬 컴퓨터에서 실행
Disable-GuestAccount

# 원격 컴퓨터에서 실행하는 경우
# Disable-GuestAccount -ComputerName "RemoteComputerName"
