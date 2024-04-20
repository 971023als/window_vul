import os
import json
import subprocess
import winreg

def check_admin():
    """Check if the script is running with administrator privileges."""
    try:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
    except Exception:
        return False

def setup_directories(computer_name):
    """Prepare directories for storing raw data and results."""
    raw_dir = f"C:\\Window_{computer_name}_raw"
    result_dir = f"C:\\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def get_rdp_session_timeout():
    """Retrieve RDP session timeout settings from the registry."""
    try:
        key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp")
        value, _ = winreg.QueryValueEx(key, "MaxIdleTime")
        winreg.CloseKey(key)
        return value
    except FileNotFoundError:
        return None
    except OSError:
        return None

def main():
    if not check_admin():
        print("이 스크립트는 관리자 권한으로 실행되어야 합니다.")
        return
    
    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_directories(computer_name)
    
    max_idle_time = get_rdp_session_timeout()
    results = {
        "분류": "서비스관리",
        "코드": "W-53",
        "위험도": "상",
        "진단 항목": "원격터미널 접속 타임아웃 설정",
        "진단 결과": "양호" if max_idle_time else "취약",
        "현황": [],
        "대응방안": "원격터미널 접속 타임아웃 설정"
    }

    if max_idle_time is None:
        results["현황"].append("RDP 세션 타임아웃이 설정되지 않았습니다. 이는 취약점이 될 수 있습니다.")
    else:
        results["현황"].append(f"RDP 세션 타임아웃이 {max_idle_time}ms로 설정되어 있습니다.")
    
    # Save the results to a JSON file
    json_path = os.path.join(result_dir, f"W-53_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
