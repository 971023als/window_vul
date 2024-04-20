import os
import json
import subprocess
import winreg
from win32com.shell import shell

def check_admin():
    return shell.IsUserAnAdmin()

def setup_directories(computer_name):
    raw_dir = f"C:\\Window_{computer_name}_raw"
    result_dir = f"C:\\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def get_min_encryption_level():
    reg_key_path = r"SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
    try:
        registry_key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, reg_key_path, 0, winreg.KEY_READ)
        min_encryption_level, _ = winreg.QueryValueEx(registry_key, "MinEncryptionLevel")
        winreg.CloseKey(registry_key)
        return min_encryption_level
    except WindowsError:
        return None

def audit_rdp_encryption():
    min_encryption_level = get_min_encryption_level()
    result = {
        "분류": "서비스관리",
        "코드": "W-44",
        "위험도": "상",
        "진단 항목": "터미널 서비스 암호화 수준 설정",
        "진단 결과": "양호",  # 기본 값을 "양호"로 가정
        "현황": [],
        "대응방안": "터미널 서비스 암호화 수준 설정"
    }

    if min_encryption_level is not None:
        if min_encryption_level > 1:
            result["현황"].append("RDP 최소 암호화 수준이 적절히 설정되어 있습니다.")
        else:
            result["진단 결과"] = "취약"
            result["현황"].append("RDP 최소 암호화 수준이 낮게 설정되어 있어 보안에 취약할 수 있습니다.")
    else:
        result["진단 결과"] = "오류"
        result["현황"].append("RDP 최소 암호화 수준을 조회하는 데 실패했습니다.")

    return result

def save_results(results, result_dir):
    file_path = os.path.join(result_dir, "W-44_diagnostics_results.json")
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=4)
    print(f"결과가 저장되었습니다: {file_path}")

if __name__ == "__main__":
    if not check_admin():
        # Restart script with admin rights if not already admin
        subprocess.call(['powershell', 'Start-Process', 'python', f'"{os.path.abspath(__file__)}"', '-Verb', 'RunAs'])
    else:
        computer_name = os.getenv('COMPUTERNAME', 'UNKNOWN_PC')
        raw_dir, result_dir = setup_directories(computer_name)
        audit_results = audit_rdp_encryption()
        save_results(audit_results, result_dir)
