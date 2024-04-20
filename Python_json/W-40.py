import os
import json
from pathlib import Path
import subprocess

# Define the initial JSON data structure
audit_info = {
    "분류": "서비스관리",
    "코드": "W-40",
    "위험도": "상",
    "진단 항목": "FTP 접근 제어 설정",
    "진단 결과": "양호",  # Assume 'Good' as the default state
    "현황": [],
    "대응방안": "FTP 접근 제어 설정"
}

# Request Administrator privileges if not already running with them
def request_admin():
    try:
        subprocess.check_call(['powershell', 'Start-Process', 'python', f'"{os.path.abspath(__file__)}"', '-Verb', 'RunAs'])
    except subprocess.CalledProcessError:
        pass
    exit()

# Setup environment and directories
def setup_environment():
    computer_name = os.getenv('COMPUTERNAME', 'UNKNOWN_PC')
    raw_dir = Path(f"C:\\Window_{computer_name}_raw")
    result_dir = Path(f"C:\\Window_{computer_name}_result")
    raw_dir.mkdir(parents=True, exist_ok=True)
    result_dir.mkdir(parents=True, exist_ok=True)
    return raw_dir, result_dir

# Simulate FTP access control diagnostics
def check_ftp_access_control():
    # This is a placeholder for the actual diagnostic logic
    # In reality, you would implement checks against FTP server settings here
    is_ftp_secure = False  # Simulate an insecure condition
    return is_ftp_secure

# Main function
def main():
    if os.name == 'nt':
        request_admin()

    raw_dir, result_dir = setup_environment()
    is_ftp_secure = check_ftp_access_control()

    if not is_ftp_secure:
        audit_info["진단 결과"] = "위험"
        audit_info["현황"].append("특정 IP 주소에서만 FTP 접속이 허용되어야 하나, 현재 모든 IP에서 접속이 허용되어 있어 취약합니다.")
    else:
        audit_info["현황"].append("특정 IP 주소에서만 FTP 접속이 허용되어 있습니다.")

    # Save the audit results to a JSON file with Korean characters preserved
    json_path = result_dir / "W-40.json"
    with open(json_path, 'w', encoding='utf-8') as json_file:
        json.dump(audit_info, json_file, ensure_ascii=False, indent=4)

if __name__ == "__main__":
    main()
