import os
import json
import subprocess
import platform
from win32com.client import GetObject

def check_admin():
    import ctypes
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

def setup_directories(computer_name):
    raw_dir = f"C:\\Window_{computer_name}_raw"
    result_dir = f"C:\\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def get_os_info():
    wmi = GetObject('winmgmts:')
    os_info = wmi.InstancesOf('Win32_OperatingSystem')[0]
    return os_info.Version, os_info.ServicePackMajorVersion

def audit_service_pack():
    version, service_pack = get_os_info()
    result = {
        "분류": "서비스관리",
        "코드": "W-43",
        "위험도": "상",
        "진단항목": "최신 서비스팩 적용",
        "진단결과": "양호",  # 기본 값을 "양호"로 가정
        "현황": [],
        "대응방안": "최신 서비스팩 적용"
    }

    if service_pack == 0:
        result["진단결과"] = "취약"
        result["현황"].append("최신 서비스팩이 적용되지 않았습니다.")
    else:
        result["현황"].append("최신 서비스팩이 적용되어 있습니다.")

    return result

def save_results(results, result_dir):
    file_path = os.path.join(result_dir, "W-43_diagnostics_results.json")
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=4)

if __name__ == "__main__":
    if not check_admin():
        subprocess.call(['powershell', 'Start-Process', 'python', f'"{os.path.abspath(__file__)}"', '-Verb', 'RunAs'])
    else:
        computer_name = os.getenv('COMPUTERNAME', 'UNKNOWN_PC')
        raw_dir, result_dir = setup_directories(computer_name)
        audit_result = audit_service_pack()
        save_results(audit_result, result_dir)
        print(f"결과가 저장되었습니다: {os.path.join(result_dir, 'W-43_diagnostics_results.json')}")
