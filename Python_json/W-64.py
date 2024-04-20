import os
import json
import subprocess
import winreg as reg

def check_admin():
    """Check if the script is run as administrator."""
    try:
        return os.getuid() == 0
    except AttributeError:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin() != 0

def setup_directories(computer_name):
    """Prepare directories for raw data and results."""
    raw_directory = fr"C:\Windows_Security_Audit\{computer_name}_raw"
    result_directory = fr"C:\Windows_Security_Audit\{computer_name}_result"
    os.makedirs(raw_directory, exist_ok=True)
    os.makedirs(result_directory, exist_ok=True)
    return raw_directory, result_directory

def get_screensaver_settings():
    """Retrieve screensaver settings from the registry."""
    path = r"Control Panel\Desktop"
    try:
        with reg.OpenKey(reg.HKEY_CURRENT_USER, path) as key:
            screen_save_active = reg.QueryValueEx(key, "ScreenSaveActive")[0]
            screen_saver_is_secure = reg.QueryValueEx(key, "ScreenSaverIsSecure")[0]
            screen_save_timeout = reg.QueryValueEx(key, "ScreenSaveTimeout")[0]
            return screen_save_active, screen_saver_is_secure, screen_save_timeout
    except FileNotFoundError:
        return None, None, None

def analyze_settings():
    """Analyze screensaver settings and generate report."""
    screen_save_active, screen_saver_is_secure, screen_save_timeout = get_screensaver_settings()
    result = {
        "분류": "보안관리",
        "코드": "W-64",
        "위험도": "상",
        "진단 항목": "화면보호기설정",
        "진단 결과": "양호",
        "현황": [],
        "대응방안": "화면보호기설정 조정"
    }

    if screen_save_active == "1":
        if screen_saver_is_secure == "1":
            if int(screen_save_timeout) < 600:
                result["진단 결과"] = "취약"
                result["현황"].append("스크린 세이버가 활성화되었으나, 타임아웃 시간이 10분 미만으로 설정되어 있습니다.")
            else:
                result["현황"].append("스크린 세이버가 적절히 설정되어 있습니다.")
        else:
            result["진단 결과"] = "취약"
            result["현황"].append("안전한 로그온이 요구되지 않는 스크린 세이버가 설정되어 있습니다.")
    else:
        result["진단 결과"] = "취약"
        result["현황"].append("스크린 세이버가 비활성화되어 있습니다.")
    
    return result

def main():
    if not check_admin():
        print("이 스크립트는 관리자 권한으로 실행되어야 합니다.")
        return

    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_directories(computer_name)
    result = analyze_settings()

    # Save results to a JSON file
    json_path = os.path.join(result_dir, f"W-64_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as file:
        json.dump(result, file, ensure_ascii=False, indent=4)

    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
