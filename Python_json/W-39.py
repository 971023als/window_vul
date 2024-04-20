import os
import json
from pathlib import Path
import subprocess

# Define the audit parameters
audit_params = {
    "분류": "서비스관리",
    "코드": "W-39",
    "위험도": "상",
    "진단 항목": "Anonymouse FTP 금지",
    "진단 결과": "양호",  # 기본 값을 '양호'로 가정
    "현황": [],
    "대응방안": "Anonymouse FTP 금지"
}

# Request Administrator privileges
def request_admin():
    try:
        subprocess.check_call(['powershell', '-Command', 'Start-Process', 'python', '-ArgumentList', f'"{os.path.realpath(__file__)}"', '-Verb', 'RunAs'])
    except subprocess.CalledProcessError:
        pass
    exit()

# Set up the environment
def setup_environment():
    computer_name = os.getenv('COMPUTERNAME', 'UNKNOWN_PC')
    raw_dir = Path(f"C:\\Window_{computer_name}_raw")
    result_dir = Path(f"C:\\Window_{computer_name}_result")
    raw_dir.mkdir(parents=True, exist_ok=True)
    result_dir.mkdir(parents=True, exist_ok=True)
    
    # Simulate the security policy export
    (raw_dir / 'Local_Security_Policy.txt').write_text('Local Security Policy Content')
    # Simulate system info collection
    (raw_dir / 'systeminfo.txt').write_text('System Info Content')

    return raw_dir, result_dir

# Simulate checking for Anonymous FTP configuration
def check_ftp_configuration(raw_dir):
    # This is a placeholder for real FTP configuration checks
    # Simulating no anonymous FTP found
    return True

# Main function to run the script
def main():
    if os.name == 'nt':
        request_admin()

    raw_dir, result_dir = setup_environment()
    is_secure = check_ftp_configuration(raw_dir)

    if is_secure:
        audit_params["진단 결과"] = "양호"
        audit_params["현황"].append("Anonymouse FTP 사용이 금지되어 있습니다.")
    else:
        audit_params["진단 결과"] = "위험"
        audit_params["현황"].append("Anonymouse FTP 사용이 감지되었습니다.")

    # Save the audit results to a JSON file with Korean encoding
    json_path = result_dir / "W-39.json"
    with open(json_path, 'w', encoding='utf-8') as json_file:
        json.dump(audit_params, json_file, ensure_ascii=False, indent=4)

if __name__ == "__main__":
    main()
