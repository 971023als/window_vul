import os
import subprocess
import json
from winreg import ConnectRegistry, OpenKey, QueryValueEx, HKEY_LOCAL_MACHINE

def check_admin():
    try:
        return os.getuid() == 0
    except AttributeError:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin() != 0

def setup_environment():
    computer_name = os.getenv('COMPUTERNAME', 'UNKNOWN_PC')
    raw_dir = f"C:\\Window_{computer_name}_raw"
    result_dir = f"C:\\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def check_dns_zone_transfer():
    audit_result = {
        "분류": "서비스관리",
        "코드": "W-41",
        "위험도": "상",
        "진단 항목": "DNS Zone Transfer 설정",
        "진단 결과": "양호",  # 기본을 "양호"로 가정
        "현황": [],
        "대응방안": "DNS Zone Transfer 설정"
    }

    try:
        registry = ConnectRegistry(None, HKEY_LOCAL_MACHINE)
        path = r"SOFTWARE\Microsoft\Windows NT\CurrentVersion\DNS Server\Zones"
        key = OpenKey(registry, path)
        secure_secondaries, _ = QueryValueEx(key, "SecureSecondaries")
        if secure_secondaries == 2:
            audit_result["진단 결과"] = "양호"
            audit_result["현황"].append("DNS 전송 설정이 안전하게 구성되어 있습니다.")
        else:
            audit_result["진단 결과"] = "취약"
            audit_result["현황"].append("DNS 전송 설정이 취약한 구성으로 되어 있습니다. DNS 전송 설정을 보안 강화를 위해 수정해야 합니다.")
    except FileNotFoundError:
        audit_result["진단 결과"] = "정보"
        audit_result["현황"].append("DNS 서비스가 실행 중이지 않습니다.")
    except Exception as e:
        audit_result["진단 결과"] = "오류"
        audit_result["현황"].append(str(e))

    return audit_result

def save_results(audit_result, result_dir):
    file_path = os.path.join(result_dir, "W-41.json")
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(audit_result, f, ensure_ascii=False, indent=4)

if __name__ == "__main__":
    if not check_admin():
        subprocess.call(['powershell', 'Start-Process', 'python', f'"{os.path.abspath(__file__)}"', '-Verb', 'RunAs'])
    else:
        raw_dir, result_dir = setup_environment()
        audit_result = check_dns_zone_transfer()
        save_results(audit_result, result_dir)
        print("진단 결과가 저장되었습니다:", result_dir)
