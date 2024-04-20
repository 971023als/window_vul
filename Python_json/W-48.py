import os
import json
import subprocess
import winreg

def check_admin():
    """Check if the script is running as administrator."""
    try:
        return subprocess.check_output("net session", stderr=subprocess.STDOUT, shell=True)
    except subprocess.CalledProcessError:
        return False

def setup_directories(computer_name):
    """Setup directories for storing raw and result data."""
    raw_dir = f"C:\\Window_{computer_name}_raw"
    result_dir = f"C:\\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def check_snmp_access_control():
    """Check the SNMP permitted managers in the registry."""
    try:
        registry = winreg.ConnectRegistry(None, winreg.HKEY_LOCAL_MACHINE)
        key_path = r"SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers"
        key = winreg.OpenKey(registry, key_path, 0, winreg.KEY_READ)
        managers = {}
        i = 0
        while True:
            try:
                value_name, value, _ = winreg.EnumValue(key, i)
                managers[value_name] = value
                i += 1
            except OSError:
                break
        winreg.CloseKey(key)
        return managers
    except Exception as e:
        print(f"SNMP 접근 제어 설정 검사 중 오류 발생: {str(e)}")
        return None

def audit_snmp_access():
    """Audit SNMP access control settings and save results to a JSON file."""
    computer_name = os.getenv('COMPUTERNAME', 'UNKNOWN_PC')
    raw_dir, result_dir = setup_directories(computer_name)

    managers = check_snmp_access_control()
    is_secure = bool(managers)

    results = {
        "분류": "서비스관리",
        "코드": "W-48",
        "위험도": "상",
        "진단 항목": "SNMP Access control 설정",
        "진단 결과": "경고" if not is_secure else "양호",
        "현황": ["SNMP 서비스가 실행 중이며 허용된 관리자가 구성되어 있습니다. 해당 설정은 네트워크 보안을 강화하는 데 도움이 됩니다."] if is_secure else ["SNMP 서비스가 실행 중이지만 허용된 관리자가 명확하게 구성되지 않았습니다."],
        "대응방안": "SNMP Access control 설정"
    }

    # Save results to a JSON file
    json_path = os.path.join(result_dir, f"W-48_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    if not check_admin():
        # Restart the script with admin rights if not running as admin
        subprocess.call(['powershell', 'Start-Process', 'python', f'"{os.path.abspath(__file__)}"', '-Verb', 'RunAs'])
    else:
        audit_snmp_access()
