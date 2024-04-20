import os
import json
import subprocess
from pathlib import Path
import shutil
from win32com.shell import shell

# Initialize diagnostics JSON object
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-32",
    "위험도": "상",
    "진단 항목": "해독 가능한 암호화를 사용하여 암호 저장",
    "진단 결과": "양호",  # 기본 값을 '양호'로 가정
    "현황": [],
    "대응방안": "해독 가능한 암호화를 사용하여 암호 저장 방지"
}

# Check and request administrator privileges
if not shell.IsUserAnAdmin():
    subprocess.call(['runas', '/user:Administrator', 'python'] + sys.argv)
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
(raw_dir / 'compare.txt').touch()
with open(raw_dir / 'systeminfo.txt', 'w') as f:
    subprocess.run(['systeminfo'], stdout=f)

# Analyze IIS settings
application_host_config = Path(os.environ['WINDIR']) / 'System32' / 'Inetsrv' / 'Config' / 'applicationHost.Config'
if application_host_config.exists():
    content = application_host_config.read_text()
    with open(raw_dir / 'iis_setting.txt', 'w') as file:
        file.write(content)
    binding_info = [line for line in content.split('\n') if "physicalPath" in line or "bindingInformation" in line]
    with open(raw_dir / 'iis_path1.txt', 'w') as file:
        file.writelines(binding_info)

# W-32 directory permissions check
service_running = subprocess.run(['sc', 'query', 'W3SVC'], capture_output=True, text=True)
if "RUNNING" in service_running.stdout:
    directories = raw_dir / 'iis_path1.txt'
    if directories.exists():
        with open(directories) as f:
            dirs = f.readlines()
        for dir in dirs:
            if Path(dir.strip()).exists():
                acl_output = subprocess.check_output(['icacls', dir.strip()])
                if 'Everyone' in str(acl_output):
                    message = f"위험: {dir.strip()} 디렉토리에 Everyone 그룹에 대한 액세스 권한이 부여됨"
                    with open(result_dir / f'W-Window-{computer_name}-result.txt', 'a') as result_file:
                        result_file.write(message + '\n')
                    diagnosis_result["현황"].append(message)

# Save JSON results to a file
json_file_path = result_dir / 'W-32.json'
with open(json_file_path, 'w') as file:
    json.dump(diagnosis_result, file, ensure_ascii=False, indent=4)

print("Script execution completed.")
