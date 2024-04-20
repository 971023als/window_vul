import os
import json
import subprocess
from pathlib import Path
import shutil

# Initialize the diagnostics JSON object
diagnosis_result = {
    "분류": "계정 관리",
    "코드": "W-30",
    "위험도": "높음",
    "진단항목": "비밀번호 저장을 위한 복호화 가능한 암호화 사용",
    "진단결과": "양호",  # 기본 상태를 '양호'로 가정
    "현황": [],
    "대응방안": "비밀번호 저장을 위해 비복호화 가능한 암호화 사용"
}

# Check and request administrator privileges
if not os.getuid() == 0:
    print("관리자 권한이 필요합니다...")
    subprocess.call(['sudo', 'python3'] + sys.argv)
    exit()

# Environment and directory setup
computer_name = os.environ['COMPUTERNAME']
raw_dir = Path(f"C:\\Window_{computer_name}_raw")
result_dir = Path(f"C:\\Window_{computer_name}_result")

# Clear existing directories and create new ones
shutil.rmtree(raw_dir, ignore_errors=True)
shutil.rmtree(result_dir, ignore_errors=True)
raw_dir.mkdir(parents=True, exist_ok=True)
result_dir.mkdir(parents=True, exist_ok=True)

# Export local security policy and save system info
subprocess.run(['secedit', '/export', '/cfg', str(raw_dir / "Local_Security_Policy.txt")])
(raw_dir / 'install_path.txt').write_text(str(raw_dir))
system_info = subprocess.check_output(['systeminfo']).decode()
(raw_dir / 'systeminfo.txt').write_text(system_info)

# Analyze IIS settings
application_host_config_path = Path(os.environ['WINDIR']) + r"\System32\Inetsrv\Config\applicationHost.Config"
if application_host_config_path.exists():
    content = application_host_config_path.read_text()
    (raw_dir / 'iis_setting.txt').write_text(content)
    physical_paths = '\n'.join(line for line in content.splitlines() if "physicalPath" in line or "bindingInformation" in line)
    (raw_dir / 'iis_path_info.txt').write_text(physical_paths)
else:
    print("IIS 설정 파일을 찾을 수 없습니다.")

# Copy MetaBase.xml if it exists
meta_base_path = Path(os.environ['WINDIR']) + r"\system32\inetsrv\MetaBase.xml"
if meta_base_path.exists():
    meta_base_content = meta_base_path.read_text()
    (raw_dir / 'iis_setting.txt').write_text(meta_base_content, append=True)
else:
    print("MetaBase.xml 파일을 찾을 수 없습니다.")

# W-30 diagnostic checks
service_running = subprocess.run(['sc', 'query', 'W3SVC'], capture_output=True, text=True)
if "RUNNING" in service_running.stdout:
    asa_files = any('.asa' in line or '.asax' in line for line in (raw_dir / 'iis_setting.txt').read_text().splitlines())
    if asa_files:
        diagnosis_result["현황"].append("정책 위반: .asa 또는 .asax 파일에 대한 제한이 없습니다.")
        diagnosis_result["진단결과"] = "취약"
    else:
        diagnosis_result["현황"].append("정책 준수: .asa 및 .asax 파일이 적절히 제한되어 있습니다.")
else:
    diagnosis_result["현황"].append("월드 와이드 웹 퍼블리싱 서비스가 실행되지 않고 있습니다: .asa 또는 .asax 파일 검사가 필요 없습니다.")

# Save the JSON results to a file
json_file_path = result_dir / 'W-30.json'
with open(json_file_path, 'w') as file:
    json.dump(diagnosis_result, file, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
