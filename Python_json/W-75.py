import json
import os
import subprocess
import winreg

def is_admin():
    """ Check if the script is running as administrator. """
    try:
        return os.getuid() == 0
    except AttributeError:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin() != 0

def setup_environment(computer_name):
    """ Setup the environment for storing results and configurations. """
    raw_dir = f"C:\\Window_{computer_name}_raw"
    result_dir = f"C:\\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def get_legal_notice_settings():
    """ Retrieve legal notice settings from the registry. """
    try:
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon") as key:
            caption = winreg.QueryValueEx(key, "LegalNoticeCaption")[0]
            text = winreg.QueryValueEx(key, "LegalNoticeText")[0]
            return caption, text
    except FileNotFoundError:
        return None, None

def main():
    if not is_admin():
        print("스크립트는 관리자 권한으로 실행되어야 합니다.")
        return

    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_environment(computer_name)
    caption, text = get_legal_notice_settings()
    
    result = {
        "분류": "보안관리",
        "코드": "W-75",
        "위험도": "상",
        "진단 항목": "경고 메시지 설정",
        "진단 결과": "양호" if not caption and not text else "취약",
        "현황": ["로그인 시 법적 고지가 설정되지 않았습니다."] if not caption and not text else ["로그인 시 법적 고지가 설정되어 있습니다."],
        "대응방안": "경고 메시지 설정"
    }

    # Save JSON data to a file
    json_path = os.path.join(result_dir, f"W-75_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as json_file:
        json.dump(result, json_file, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
