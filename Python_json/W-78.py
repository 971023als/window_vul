import json
import os
import subprocess
from winreg import *

def check_admin_rights():
    """Check if the script is running with administrative privileges."""
    try:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
    except AttributeError:
        return os.getuid() == 0

def setup_directories(computer_name):
    """Create directories for storing raw and result data."""
    raw_dir = f"C:\\Window_{computer_name}_raw"
    result_dir = f"C:\\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def export_local_security_policy(raw_dir):
    """Export the local security policy to a file."""
    output_file = os.path.join(raw_dir, "Local_Security_Policy.txt")
    subprocess.run(['secedit', '/export', '/cfg', output_file], check=True)

def analyze_security_settings(raw_dir):
    """Analyze security settings for digital encryption or signing of secure channel data."""
    policy_file = os.path.join(raw_dir, "Local_Security_Policy.txt")
    with open(policy_file, 'r') as file:
        policies = file.readlines()

    conditions_met = any("RequireSignOrSeal = 1" in line or "SealSecureChannel = 1" in line or
                         "SignSecureChannel = 1" in line for line in policies)
    return conditions_met

def main():
    if not check_admin_rights():
        print("관리자 권한으로 실행해야 합니다.")
        return

    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_directories(computer_name)
    export_local_security_policy(raw_dir)

    conditions_met = analyze_security_settings(raw_dir)

    # Define the JSON data structure
    security_data = {
        "분류": "보안관리",
        "코드": "W-78",
        "위험도": "상",
        "진단 항목": "보안 채널 데이터 디지털 암호화 또는 서명",
        "진단 결과": "양호" if conditions_met else "취약",
        "현황": ["모든 조건 만족"] if conditions_met else ["하나 이상의 조건 불만족"],
        "대응방안": "보안 채널 데이터 디지털 암호화 또는 서명 설정 조정"
    }

    # Save the JSON data to a file
    json_path = os.path.join(result_dir, f"W-78_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(security_data, f, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

    # Cleanup
    os.remove(os.path.join(raw_dir, "Local_Security_Policy.txt"))
    print("스크립트가 완료되었습니다.")

if __name__ == "__main__":
    main()
