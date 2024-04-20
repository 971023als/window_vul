import os
import json
import subprocess
from pathlib import Path
import shutil
import xml.etree.ElementTree as ET

# JSON 객체 초기화
diagnosis_result = {
    "분류": "서비스관리",
    "코드": "W-23",
    "위험도": "상",
    "진단항목": "IIS 디렉토리 리스팅 제거",
    "진단결과": "양호",  # 기본 값을 "양호"로 가정
    "현황": [],
    "대응방안": "IIS 디렉토리 리스팅 제거"
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
(raw_dir / 'compare.txt').touch()
with open(raw_dir / 'install_path.txt', 'w') as f:
    f.write(str(raw_dir))
with open(raw_dir / 'systeminfo.txt', 'w') as f:
    subprocess.run(['systeminfo'], stdout=f)

# IIS 설정 분석
application_host_config_path = Path(os.environ['WINDIR']) / 'System32' / 'Inetsrv' / 'Config' / 'applicationHost.Config'
with open(application_host_config_path) as file:
    content = file.read()
with open(raw_dir / 'iis_setting.txt', 'w') as file:
    file.write(content)

# Assuming directory paths are collected correctly earlier in the script
iis_paths = []  # List of paths to check, needs proper initialization based on the actual setup

# Update the JSON object based on the directory browsing check
service_status = subprocess.check_output(['sc', 'query', 'w3svc'], text=True)
is_running = "RUNNING" in service_status

if is_running:
    for path in iis_paths:
        web_config_path = Path(path) / "web.config"
        try:
            tree = ET.parse(web_config_path)
            root = tree.getroot()
            # Checking for directory browsing settings
            if root.findall(".//directoryBrowse[@enabled='true']"):
                diagnosis_result["현황"].append("불안전한 상태: 디렉토리 브라우징이 활성화되어 있습니다.")
                diagnosis_result["진단결과"] = "취약"
                break
        except FileNotFoundError:
            continue
    else:
        diagnosis_result["현황"].append("안전한 상태: 디렉토리 브라우징이 비활성화되어 있습니다.")
        diagnosis_result["진단결과"] = "양호"
else:
    diagnosis_result["현황"].append("안전한 상태: World Wide Web Publishing Service가 실행되지 않고 있습니다.")
    diagnosis_result["진단결과"] = "양호"

# Save the JSON results to a file
json_file_path = result_dir / 'W-23.json'
with open(json_file_path, 'w') as file:
    json.dump(diagnosis_result, file, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
