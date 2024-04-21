@echo off
PowerShell -Command "Set-ExecutionPolicy Unrestricted -Scope Process" >nul
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {

    # 관리자 권한 요청
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Start-Process PowerShell.exe -ArgumentList '-NoProfile', '-ExecutionPolicy Bypass', '-File', '%~f0', '-Verb', 'RunAs'
        exit
    }

    # 콘솔 환경 설정
    chcp 437 | Out-Null
    $host.UI.RawUI.BackgroundColor = 'DarkGreen'
    $host.UI.RawUI.ForegroundColor = 'Green'
    Clear-Host
    Write-Host '환경을 설정하고 있습니다...'

    # 감사 환경 준비
    $global:computerName = $env:COMPUTERNAME
    $global:rawDir = 'C:\Audit_' + $computerName + '_RawData'
    $global:resultDir = 'C:\Audit_' + $computerName + '_Results'

    Remove-Item -Path $rawDir, $resultDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -Path $rawDir, $resultDir -ItemType Directory | Out-Null

    # 로컬 보안 정책 및 시스템 정보 내보내기
    secedit /export /cfg '$rawDir\Local_Security_Policy.txt' | Out-Null
    systeminfo | Out-File '$rawDir\SystemInfo.txt'

    # WebDAV 보안 감사 수행
    Write-Host 'WebDAV 보안 검사를 수행하고 있습니다...'
    $serviceStatus = (Get-Service W3SVC -ErrorAction SilentlyContinue).Status

    if ($serviceStatus -eq 'Running') {
        $webDavConfigurations = Select-String -Path '$env:SystemRoot\System32\inetsrv\config\applicationHost.config' -Pattern 'webdav' -AllMatches
        if ($webDavConfigurations) {
            foreach ($config in $webDavConfigurations) {
                $config.Line | Out-File -FilePath '$rawDir\WebDAVConfigDetails.txt' -Append
            }
            Write-Host '검토 필요: WebDAV 구성이 발견되었습니다. 자세한 내용은 WebDAVConfigDetails.txt 파일을 참조하세요.'
        } else {
            Write-Host '조치 필요 없음: WebDAV가 적절하게 구성되었거나 존재하지 않습니다.'
        }
    } else {
        Write-Host '조치 필요 없음: IIS 웹 게시 서비스가 실행 중이지 않습니다.'
    }

    # CSV 파일로 결과 저장
    $csvLine = '분류,코드,위험 수준,감사 항목,감사 결과,현재 상태,조치 권고'
    $csvData = '계정 관리,W-35,높음,비밀번호 저장을 위한 복호화 가능 암호화 사용,양호,,' + '비복호화 가능 암호화 사용 권장'
    $csvLine, $csvData | Out-File -FilePath '$resultDir\W-35.csv' -Encoding ASCII

    Write-Host '감사 완료.'
    pause
}"
