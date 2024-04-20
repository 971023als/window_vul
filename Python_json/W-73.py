import os
import json
import winreg
import subprocess

def check_admin_rights():
    """ Check if the script is run with administrator privileges. """
    try:
        return os.getuid() == 0
    except AttributeError:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin() != 0

def setup_directories(computer_name):
    """ Setup directories for storing results. """
    raw_dir = f"C:\\Window_{computer_name}_raw"
    result_dir = f"C:\\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def export_local_security_policy(raw_dir):
    """ Export local security policies to a text file. """
    output_path = os.path.join(raw_dir, "Local_Security_Policy.txt")
    subprocess.run(['secedit', '/export', '/cfg', output_path], check=True)
    return output_path

def check_printer_driver_installation_policy(policy_file):
    """ Check if the policy for adding printer drivers is adequately set. """
    with open(policy_file, 'r', encoding='utf-16') as file:
        policy_content = file.read()
    return 'AddPrinterDrivers = 1' in policy_content

def main():
    if not check_admin_rights():
        print("이 스크립트는 관리자 권한으로 실행되어야 합니다.")
        return
    
    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_directories(computer_name)
    policy_file = export_local_security_policy(raw_dir)
    policy_is_adequate = check_printer_driver_installation_policy(policy_file)
    
    result = {
        "분류": "보안관리",
        "코드": "W-73",
        "위험도": "상",
        "진단 항목": "사용자가 프린터 드라이버를 설치할 수 없게 함",
        "진단 결과": "양호" if policy_is_adequate else "취약",
        "현황": ["프린터 드라이버 추가 권한이 적절하게 설정되어 있습니다."] if policy_is_adequate else ["프린터 드라이버 추가 권한이 적절하지 않게 설정되어 있습니다."],
        "대응방안": "사용자가 프린터 드라이버를 설치할 수 없도록 설정 조정"
    }
    
    json_path = os.path.join(result_dir, f"W-73_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
