import os
import json
import subprocess
import winreg

def check_admin():
    """Check if the script is run as an administrator."""
    try:
        return os.getuid() == 0
    except AttributeError:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin() != 0

def setup_directories(computer_name):
    """Create directories for storing raw data and results."""
    raw_dir = fr"C:\Window_{computer_name}_raw"
    result_dir = fr"C:\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def check_event_log_settings():
    """Check the configuration of system event logs."""
    inadequate_settings = False
    results = []
    log_keys = ["Application", "Security", "System"]
    with winreg.ConnectRegistry(None, winreg.HKEY_LOCAL_MACHINE) as hkey:
        for key in log_keys:
            path = fr"SYSTEM\CurrentControlSet\Services\Eventlog\{key}"
            try:
                with winreg.OpenKey(hkey, path) as log_key:
                    max_size, _ = winreg.QueryValueEx(log_key, "MaxSize")
                    retention, _ = winreg.QueryValueEx(log_key, "Retention")
                    if max_size < 10485760 or retention == 0:
                        inadequate_settings = True
                        results.append(f"MaxSize for {key}: {max_size}, Retention for {key}: {retention}")
            except FileNotFoundError:
                results.append(f"Event log settings for {key} not found.")
    return inadequate_settings, results

def main():
    if not check_admin():
        print("이 스크립트는 관리자 권한으로 실행되어야 합니다.")
        return

    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_directories(computer_name)

    inadequate_settings, settings_results = check_event_log_settings()

    results = {
        "분류": "로그관리",
        "코드": "W-60",
        "위험도": "상",
        "진단 항목": "이벤트 로그 관리 설정",
        "진단 결과": "취약" if inadequate_settings else "양호",
        "현황": settings_results if inadequate_settings else ["모든 이벤트 로그가 적절하게 설정되었습니다."],
        "대응방안": "이벤트 로그 관리 설정 조정"
    }

    # Save results to a JSON file
    json_path = os.path.join(result_dir, f"W-60_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as file:
        json.dump(results, file, ensure_ascii=False, indent=4)

    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
