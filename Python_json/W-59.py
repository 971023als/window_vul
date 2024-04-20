import os
import json
import subprocess
import ctypes
from winreg import ConnectRegistry, OpenKey, HKEY_LOCAL_MACHINE, QueryValueEx, CloseKey

def is_admin():
    """Check if the user has administrative privileges."""
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except Exception:
        return False

def setup_directories(computer_name):
    """Setup directories for storing results and data."""
    raw_dir = f"C:\\Window_{computer_name}_raw"
    result_dir = f"C:\\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def check_remote_registry_service():
    """Check the status of the Remote Registry service."""
    try:
        registry = ConnectRegistry(None, HKEY_LOCAL_MACHINE)
        key = OpenKey(registry, r"SYSTEM\CurrentControlSet\Services\RemoteRegistry")
        value, _ = QueryValueEx(key, "Start")
        CloseKey(key)
        # 2 indicates auto start, and 3 is manual.
        return "취약" if value in [2, 3] else "양호"
    except FileNotFoundError:
        return "양호"

def main():
    if not is_admin():
        print("이 스크립트는 관리자 권한으로 실행되어야 합니다.")
        return
    
    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_directories(computer_name)
    
    remote_registry_status = check_remote_registry_service()
    
    results = {
        "분류": "로그관리",
        "코드": "W-59",
        "위험도": "상",
        "진단 항목": "원격으로 액세스할 수 있는 레지스트리 경로",
        "진단 결과": remote_registry_status,
        "현황": ["Remote Registry Service가 활성화되어 있으며, 이는 위험합니다."] if remote_registry_status == "취약" else ["Remote Registry Service가 비활성화되어 있으며, 이는 안전합니다."],
        "대응방안": "원격으로 액세스할 수 있는 레지스트리 경로 차단"
    }

    # Save the results to a JSON file
    json_path = os.path.join(result_dir, f"W-59_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as file:
        json.dump(results, file, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
