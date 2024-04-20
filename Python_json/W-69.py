import os
import json
import subprocess
import winreg

def check_admin_rights():
    """ Check if the script is run as administrator. """
    try:
        return os.getuid() == 0
    except AttributeError:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin() != 0

def setup_directories(computer_name):
    """ Prepare directories for storing results. """
    raw_dir = f"C:\\Window_{computer_name}_raw"
    result_dir = f"C:\\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def check_autologon():
    """ Check the registry for AutoLogon settings. """
    try:
        registry = winreg.ConnectRegistry(None, winreg.HKEY_LOCAL_MACHINE)
        key_path = r"Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
        key = winreg.OpenKey(registry, key_path, 0, winreg.KEY_READ)
        value, _ = winreg.QueryValueEx(key, "AutoAdminLogon")
        winreg.CloseKey(key)
        return value == "1"
    except WindowsError:
        return False

def main():
    if not check_admin_rights():
        print("이 스크립트는 관리자 권한으로 실행되어야 합니다.")
        return
    
    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_directories(computer_name)
    
    autologon_enabled = check_autologon()
    
    result = {
        "분류": "보안관리",
        "코드": "W-69",
        "위험도": "상",
        "진단 항목": "Autologon 기능 제어",
        "진단 결과": "양호" if not autologon_enabled else "취약",
        "현황": ["AutoAdminLogon 설정이 비활성화되어 있습니다."] if not autologon_enabled else ["AutoAdminLogon 설정이 활성화되어 있어 보안에 취약합니다."],
        "대응방안": "Autologon 기능을 비활성화하여 보안을 강화"
    }
    
    json_path = os.path.join(result_dir, f"W-69_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
