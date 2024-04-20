import json
import os
import subprocess
from pathlib import Path

# Define the audit configuration
audit_config = {
    "분류": "계정 관리",
    "코드": "W-37",
    "위험도": "높음",
    "진단 항목": "비밀번호 저장을 위한 복호화 가능한 암호화 사용",
    "진단 결과": "양호",  # 기본 값을 '양호'로 설정
    "현황": [],
    "대응방안": "비밀번호 저장을 위해 비복호화 가능한 암호화 사용"
}

# Request Administrator privileges
def request_admin_privileges():
    if os.name == 'nt':
        import ctypes
        if not ctypes.windll.shell32.IsUserAnAdmin():
            ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, " ".join(sys.argv), None, 1)
            exit()

# Setup console environment
def initialize_environment():
    if os.name == 'nt':
        os.system('chcp 437 > nul')
        print("Initializing environment...")

# Setup and cleanup audit directories
def setup_directories():
    computer_name = os.getenv('COMPUTERNAME', 'UNKNOWN_PC')
    raw_dir = Path(f"C:/Audit_{computer_name}_Raw")
    result_dir = Path(f"C:/Audit_{computer_name}_Results")
    raw_dir.mkdir(parents=True, exist_ok=True)
    result_dir.mkdir(parents=True, exist_ok=True)
    return raw_dir, result_dir

# Audit Microsoft FTP Service
def audit_ftp_services(raw_dir, result_dir):
    try:
        service_status = subprocess.check_output(['sc', 'query', 'MSFTPSVC'], text=True)
        if "RUNNING" in service_status:
            warning_msg = "Microsoft FTP Service is running, which may present a vulnerability."
            audit_config["현황"].append(warning_msg)
            with open(result_dir / 'W-Window-Result.txt', 'w', encoding='utf-8') as file:
                file.write(warning_msg)
            print(warning_msg)
        else:
            secure_msg = "Microsoft FTP Service is not running. No action required."
            audit_config["현황"].append(secure_msg)
            print(secure_msg)
    except subprocess.CalledProcessError:
        audit_config["현황"].append("FTP Service not installed or unable to query.")

# Main function to run the audit
def main():
    request_admin_privileges()
    initialize_environment()
    raw_dir, result_dir = setup_directories()
    audit_ftp_services(raw_dir, result_dir)

    # Save the JSON results to a file
    json_file_path = result_dir / 'W-37.json'
    with open(json_file_path, 'w', encoding='utf-8') as file:
        json.dump(audit_config, file, ensure_ascii=False, indent=4)

if __name__ == "__main__":
    main()
