import os
import json
import subprocess
import winreg

def is_admin():
    """Check if the script is run as administrator."""
    try:
        return os.getuid() == 0
    except AttributeError:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin() != 0

def setup_directories(computer_name):
    """Prepare directory for storing results."""
    result_dir = fr"C:\Window_{computer_name}_result"
    raw_dir = fr"C:\Window_{computer_name}_raw"
    if not os.path.exists(result_dir):
        os.makedirs(result_dir, exist_ok=True)
    if not os.path.exists(raw_dir):
        os.makedirs(raw_dir, exist_ok=True)
    return raw_dir, result_dir

def check_remote_shutdown_privilege(raw_dir):
    """Check the remote shutdown privilege settings from the security policy."""
    try:
        policy_path = os.path.join(raw_dir, "Local_Security_Policy.txt")
        with open(policy_path, 'r', encoding='utf-16') as file:
            security_policies = file.read()
        if "SeRemoteShutdownPrivilege" in security_policies:
            if "*S-1-5-32-544" in security_policies:
                return True, "원격에서 시스템 종료 권한이 Administrators 그룹에만 부여되어 있습니다."
        return False, "원격에서 시스템 종료 권한이 안전하게 설정되어 있습니다."
    except FileNotFoundError:
        return None, "보안 정책 파일을 찾을 수 없습니다."

def main():
    if not is_admin():
        print("이 스크립트는 관리자 권한으로 실행되어야 합니다.")
        return

    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_directories(computer_name)

    vulnerable, status_message = check_remote_shutdown_privilege(raw_dir)

    result = {
        "분류": "보안관리",
        "코드": "W-66",
        "위험도": "상",
        "진단 항목": "원격 시스템에서 강제로 시스템 종료",
        "진단 결과": "취약" if vulnerable else "양호",
        "현황": [status_message],
        "대응방안": "원격 시스템에서 강제로 시스템 종료 정책을 적절히 설정"
    }

    # Save results to a JSON file
    json_path = os.path.join(result_dir, f"W-66_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as file:
        json.dump(result, file, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
