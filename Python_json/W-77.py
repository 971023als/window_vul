
import json
import os
import subprocess
from winreg import *

def is_admin():
    """Check if the script is running with administrative privileges."""
    try:
        return os.getuid() == 0
    except AttributeError:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin() != 0

def setup_directories(computer_name):
    """Create directories for storing raw and result data."""
    raw_dir = f"C:\\Window_{computer_name}_raw"
    result_dir = f"C:\\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def export_local_security_policy(raw_dir):
    """Export the local security policy settings to a file."""
    output_file = os.path.join(raw_dir, "Local_Security_Policy.txt")
    subprocess.run(['secedit', '/export', '/cfg', output_file], check=True)

def get_lan_manager_auth_level():
    """Retrieve the LAN Manager authentication level from the registry."""
    try:
        with OpenKey(HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\Lsa", 0, KEY_READ) as key:
            value, _ = QueryValueEx(key, "LmCompatibilityLevel")
            return value
    except FileNotFoundError:
        return None

def main():
    if not is_admin():
        print("관리자 권한으로 실행해야 합니다.")
        return

    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_directories(computer_name)
    export_local_security_policy(raw_dir)

    lm_auth_level = get_lan_manager_auth_level()
    status = "취약" if lm_auth_level is None or lm_auth_level < 3 else "양호"
    results = {
    "분류": "보안관리",
    "코드": "W-77",
    "위험도": "상",
    "진단 항목": "LAN Manager 인증 수준",
    "진단 결과": "양호",  # 기본 값을 "양호"로 가정
    "현황": [],
    "대응방안": "LAN Manager 인증 수준 변경"
}

    if lm_auth_level is not None:
        results["현황"].append(f"현재 설정된 LAN Manager 인증 수준: {lm_auth_level}")
    else:
        results["현황"].append("LAN Manager 인증 수준이 설정되지 않았습니다.")

    json_path = os.path.join(result_dir, f"W-75_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=4)

    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
