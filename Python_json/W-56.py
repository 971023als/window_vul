import os
import subprocess
import json
import ctypes
import winreg

def is_admin():
    """Check if the program is running as administrator."""
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except Exception:
        return False

def setup_environment(computer_name):
    """Prepare directories for data storage."""
    raw_dir = f"C:\\Window_{computer_name}_raw"
    result_dir = f"C:\\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def check_antivirus_installed():
    """Check if antivirus software is installed by looking up registry keys."""
    installed = False
    try:
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\ESTsoft", 0, winreg.KEY_READ) as estsoft_key:
            if estsoft_key:
                installed = True
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\AhnLab", 0, winreg.KEY_READ) as ahnlab_key:
            if ahnlab_key:
                installed = True
    except FileNotFoundError:
        pass
    return installed

def main():
    if not is_admin():
        print("이 스크립트는 관리자 권한으로 실행되어야 합니다.")
        return
    
    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_environment(computer_name)
    
    antivirus_installed = check_antivirus_installed()
    results = {
        "분류": "패치관리",
        "코드": "W-56",
        "위험도": "상",
        "진단 항목": "백신 프로그램 업데이트",
        "진단 결과": "양호" if antivirus_installed else "취약",
        "현황": ["보안 프로그램이 설치되어 있습니다."] if antivirus_installed else ["보안 프로그램이 설치되어 있지 않습니다."],
        "대응방안": "백신 프로그램 업데이트"
    }
    
    # Save the results to a JSON file
    json_path = os.path.join(result_dir, f"W-56_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as file:
        json.dump(results, file, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
