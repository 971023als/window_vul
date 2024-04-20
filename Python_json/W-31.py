import os
import json
import subprocess
from pathlib import Path
import shutil

# Initialize diagnostics JSON object
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-31",
    "위험도": "상",
    "진단 항목": "해독 가능한 암호화를 사용하여 암호 저장",
    "진단 결과": "양호",  # 기본 상태를 '양호'로 가정
    "현황": [],
    "대응방안": "해독 가능한 암호화를 사용하여 암호 저장 방지"
}

# Check for Administrator privileges
if not os.getuid() == 0:
    print("Administrator privileges are required...")
    subprocess.call(['sudo', 'python3'] + sys.argv)
    exit()

# Set environment and directories
computer_name = os.environ['COMPUTERNAME']
raw_dir = Path(f"C:\\Window_{computer_name}_raw")
result_dir = Path(f"C:\\Window_{computer_name}_result")

# Clear existing directories and create new ones
shutil.rmtree(raw_dir, ignore_errors=True)
shutil.rmtree(result_dir, ignore_errors=True)
raw_dir.mkdir(parents=True, exist_ok=True)
result_dir.mkdir(parents=True, exist_ok=True)

# Export local security policy and system information
subprocess.run(['secedit', '/export', '/cfg', str(raw_dir / "Local_Security_Policy.txt")])
(raw_dir / 'compare.txt').touch()
with open(raw_dir / 'install_path.txt', 'w') as f:
    f.write(str(raw_dir))
with open(raw_dir / 'systeminfo.txt', 'w') as f:
    subprocess.run(['systeminfo'], stdout=f)

# Copy IIS configuration
application_host_config = Path(os.environ['WINDIR']) / 'System32' / 'Inetsrv' / 'Config' / 'applicationHost.Config'
if application_host_config.exists():
    content = application_host_config.read_text()
    with open(raw_dir / 'iis_setting.txt', 'w') as file:
        file.write(content)
    # Analyze specific settings
    with open(raw_dir / 'iis_path1.txt', 'w') as file:
        file.write('\n'.join(line for line in content.splitlines() if "physicalPath" in line or "bindingInformation" in line))

# Copy MetaBase.xml if it exists
meta_base_path = Path(os.environ['WINDIR']) / 'system32' / 'inetsrv' / 'MetaBase.xml'
if meta_base_path.exists():
    meta_base_content = meta_base_path.read_text()
    with open(raw_dir / 'iis_setting.txt', 'a') as file:
        file.write(meta_base_content)

# Additional diagnostic logic here (similar to the PowerShell script's logic)

# Write diagnostic results based on some condition
# Example conditional checks
if True:  # Replace with actual condition
    result_message = "정책 준수: 설명에 맞게 적절한 설정이 구성되어 있습니다."
else:
    result_message = "정책 위반: 설명에 맞지 않게 설정이 구성되어 있습니다."

with open(result_dir / f'W-Window-{computer_name}-result.txt', 'a') as file:
    file.write(f"W-31, | {result_message}\n")

# Save JSON results to a file
json_file_path = result_dir / 'W-31.json'
with open(json_file_path, 'w') as file:
    json.dump(diagnosis_result, file, ensure_ascii=False, indent=4)

print("Script execution completed.")
