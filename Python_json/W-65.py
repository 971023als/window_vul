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

def check_shutdown_without_logon():
    """Check the registry setting for shutdown without logon."""
    try:
        key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System")
        value, _ = winreg.QueryValueEx(key, "ShutdownWithoutLogon")
        winreg.CloseKey(key)
        return value
    except FileNotFoundError:
        return None

def setup_directories(computer_name):
    """Prepare directory for storing results."""
    result_dir = fr"C:\Window_{computer_name}_result"
    if not os.path.exists(result_dir):
        os.makedirs(result_dir, exist_ok=True)
    return result_dir

def main():
    if not is_admin():
        print("이 스크립트는 관리자 권한으로 실행되어야 합니다.")
        return

    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    result_dir = setup_directories(computer_name)

    shutdown_without_logon = check_shutdown_without_logon()

    result = {
        "분류": "보안관리",
        "코드": "W-65",
        "위험도": "상",
        "진단 항목": "로그온하지 않고 시스템 종료 허용",
        "진단 결과": "양호" if shutdown_without_logon else "취약",
        "현황": [
            "안전: '로그온 없이 시스템을 종료할 수 있는 정책'이 활성화되어 있습니다." if shutdown_without_logon
            else "취약: '로그온 없이 시스템을 종료할 수 있는 정책'이 비활성화되어 있습니다."
        ],
        "대응방안": "정책 조정을 통해 로그온하지 않고 시스템 종료를 허용하거나 차단"
    }

    # Save results to a JSON file
    json_path = os.path.join(result_dir, f"W-65_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as file:
        json.dump(result, file, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
