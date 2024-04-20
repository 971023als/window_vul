import os
import json
import subprocess
from pathlib import Path
from stat import S_IRWXU, S_IRWXG, S_IRWXO

# Define the audit configuration
audit_config = {
    "분류": "서비스관리",
    "코드": "W-38",
    "위험도": "상",
    "진단 항목": "FTP 디렉토리 접근권한 설정",
    "진단 결과": "양호",  # 기본 값을 '양호'로 가정
    "현황": [],
    "대응방안": "FTP 디렉토리 접근권한 설정"
}

# Request Administrator privileges
def request_admin():
    if os.name == 'nt':
        import ctypes
        ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, " ".join(sys.argv), None, 1)

# Check directory permissions
def check_permissions(directory):
    is_secure = True
    everyone_full_control = False

    # Check if "Everyone" has full control on directory
    st = os.stat(directory)
    if bool(st.st_mode & S_IRWXO):
        everyone_full_control = True

    return not everyone_full_control

# Setup and perform audit
def perform_audit():
    computer_name = os.environ.get('COMPUTERNAME', 'UNKNOWN_PC')
    raw_dir = Path(f"C:/Audit_{computer_name}_Raw")
    result_dir = Path(f"C:/Audit_{computer_name}_Results")
    raw_dir.mkdir(parents=True, exist_ok=True)
    result_dir.mkdir(parents=True, exist_ok=True)

    # Assume FTP directory path as an example
    ftp_directory = Path("C:/FTP")
    if ftp_directory.exists():
        is_secure = check_permissions(ftp_directory)

        if is_secure:
            audit_config["진단 결과"] = "양호"
            audit_config["현황"].append("FTP 디렉토리 접근권한이 적절히 설정됨.")
        else:
            audit_config["진단 결과"] = "위험"
            audit_config["현황"].append("EVERYONE 그룹에 대한 FullControl 접근 권한이 발견되어 취약합니다.")

    # Save the results in a JSON file with Korean encoding
    json_path = result_dir / "W-38.json"
    with open(json_path, 'w', encoding='utf-8') as json_file:
        json.dump(audit_config, json_file, ensure_ascii=False, indent=4)

# Main function
if __name__ == "__main__":
    request_admin()
    perform_audit()
