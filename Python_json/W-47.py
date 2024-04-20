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

def check_snmp_community_strings():
    """Check the SNMP community strings for default insecure settings."""
    try:
        registry = winreg.ConnectRegistry(None, winreg.HKEY_LOCAL_MACHINE)
        key = winreg.OpenKey(registry, r"SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities")
        result = {}
        i = 0
        while True:
            try:
                name, value, _ = winreg.EnumValue(key, i)
                result[name] = value
                i += 1
            except OSError:
                break
        winreg.CloseKey(key)
        return result
    except Exception as e:
        print(f"SNMP 커뮤니티 스트링 검사 중 오류 발생: {str(e)}")
        return None

def audit_snmp_community():
    """Audit the SNMP service community strings and save results to a JSON file."""
    computer_name = os.getenv('COMPUTERNAME', 'UNKNOWN_PC')
    raw_dir, result_dir = setup_directories(computer_name)

    communities = check_snmp_community_strings()
    insecure_defaults = ['public', 'private']

    # Assessing the security of community strings
    insecure = any(comm in communities for comm in insecure_defaults)

    results = {
        "분류": "서비스관리",
        "코드": "W-47",
        "위험도": "상",
        "진단 항목": "SNMP 서비스 커뮤니티스트링의 복잡성 설정",
        "진단 결과": "경고" if insecure else "양호",
        "현황": ["SNMP 서비스가 실행 중이며 기본 커뮤니티 스트링인 'public' 또는 'private'를 사용하고 있습니다. 이는 네트워크에 보안 취약점을 노출시킬 수 있습니다."] if insecure else ["SNMP 서비스가 실행 중이지만, 'public' 또는 'private'와 같은 기본 커뮤니티 스트링을 사용하고 있지 않습니다."],
        "대응방안": "SNMP 서비스 커뮤니티스트링의 복잡성 설정"
    }

    # Save results to a JSON file
    json_path = os.path.join(result_dir, f"W-47_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    if not check_admin():
        # Restart the script with admin rights if not running as admin
        subprocess.call(['powershell', 'Start-Process', 'python', f'"{os.path.abspath(__file__)}"', '-Verb', 'RunAs'])
    else:
        audit_snmp_community()
