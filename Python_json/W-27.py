import os
import json
import subprocess
from pathlib import Path
import shutil
import winreg

# JSON 객체 초기화
diagnosis_result = {
    "분류": "계정 관리",
    "코드": "W-27",
    "위험도": "높음",
    "진단항목": "비밀번호 저장을 위한 복호화 가능한 암호화 사용",
    "진단결과": "양호",  # 기본 상태를 '양호'로 가정
    "현황": [],
    "대응방안": "비밀번호 저장을 위한 복호화 가능한 암호화 사용"
}

# 관리자 권한 확인 및 요청
if not os.getuid() == 0:
    print("관리자 권한이 필요합니다...")
    subprocess.call(['sudo', 'python3'] + sys.argv)
    sys.exit()

# 초기 설정
computer_name = os.environ['COMPUTERNAME']
raw_dir = Path(f"C:\\Window_{computer_name}_raw")
result_dir = Path(f"C:\\Window_{computer_name}_result")

# 디렉터리 초기화
shutil.rmtree(raw_dir, ignore_errors=True)
shutil.rmtree(result_dir, ignore_errors=True)
raw_dir.mkdir(parents=True, exist_ok=True)
result_dir.mkdir(parents=True, exist_ok=True)

# 보안 설정 및 시스템 정보 수집
subprocess.run(['secedit', '/export', '/cfg', str(raw_dir / "Local_Security_Policy.txt")])
with open(raw_dir / 'install_path.txt', 'w') as f:
    f.write(str(raw_dir))
with open(raw_dir / 'systeminfo.txt', 'w') as f:
    subprocess.run(['systeminfo'], stdout=f)

# IIS 설정 분석
application_host_config_path = Path(os.environ['WINDIR']) / 'System32' / 'Inetsrv' / 'Config' / 'applicationHost.Config'
if application_host_config_path.exists():
    with open(application_host_config_path) as file:
        content = file.read()
    with open(raw_dir / 'iis_setting.txt', 'w') as file:
        file.write(content)

# IISADMIN 서비스 계정 검사
try:
    service_status = subprocess.check_output(['sc', 'query', 'W3SVC'], text=True)
    if "RUNNING" in service_status:
        key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Services\IISADMIN")
        object_name, _ = winreg.QueryValueEx(key, "ObjectName")
        if object_name.lower() != "localsystem":
            diagnosis_result["현황"].append("IISADMIN 서비스가 LocalSystem 계정에서 실행되지 않고 있습니다. 특별한 조치가 필요하지 않습니다.")
        else:
            diagnosis_result["현황"].append("IISADMIN 서비스가 LocalSystem 계정에서 실행되고 있습니다. 권장되지 않습니다.")
    else:
        diagnosis_result["현황"].append("월드 와이드 웹 퍼블리싱 서비스가 실행되지 않고 있습니다. IIS 관련 보안 구성 검토가 필요 없습니다.")
except subprocess.CalledProcessError:
    diagnosis_result["현황"].append("IIS 서비스 상태 확인 실패.")

# JSON 결과를 파일에 저장
json_file_path = result_dir / 'W-27.json'
with open(json_file_path, 'w') as file:
    json.dump(diagnosis_result, file, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
