import os
import json
import winreg

def check_admin():
    """Check if the script is run as an administrator."""
    try:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
    except:
        return False

def setup_directories(computer_name):
    """Create directories for storing raw data and results."""
    raw_dir = fr"C:\Window_{computer_name}_raw"
    result_dir = fr"C:\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def check_antivirus_installed():
    """Check if specific antivirus software is installed."""
    software_keys = [r"SOFTWARE\ESTsoft", r"SOFTWARE\AhnLab"]
    installed = False
    installed_details = []
    
    for key in software_keys:
        try:
            with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, key) as handle:
                installed = True
                installed_details.append(f"{key} 백신 소프트웨어가 설치되어 있습니다.")
                break
        except FileNotFoundError:
            continue
    
    if not installed:
        installed_details.append("ESTsoft 또는 AhnLab 백신 소프트웨어가 설치되지 않았습니다.")

    return installed, installed_details

def main():
    if not check_admin():
        print("이 스크립트는 관리자 권한으로 실행되어야 합니다.")
        return

    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_directories(computer_name)
    
    installed, details = check_antivirus_installed()
    results = {
        "분류": "보안관리",
        "코드": "W-62",
        "위험도": "상",
        "진단 항목": "백신 프로그램 설치",
        "진단 결과": "양호" if installed else "취약",
        "현황": details,
        "대응방안": "백신 프로그램 설치"
    }

    # Save results to a JSON file
    json_path = os.path.join(result_dir, f"W-62_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as file:
        json.dump(results, file, ensure_ascii=False, indent=4)

    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
