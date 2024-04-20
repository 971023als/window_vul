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

def check_dns_service():
    """Check DNS service settings from the registry."""
    try:
        registry = winreg.ConnectRegistry(None, winreg.HKEY_LOCAL_MACHINE)
        key_path = r"SOFTWARE\Microsoft\Windows NT\CurrentVersion\DNS Server\Zones"
        key = winreg.OpenKey(registry, key_path, 0, winreg.KEY_READ)
        allow_update = winreg.QueryValueEx(key, "AllowUpdate")[0]
        winreg.CloseKey(key)
        return allow_update == 0  # Return True if dynamic updates are disabled
    except Exception as e:
        print(f"DNS 서비스 동적 업데이트 설정 검사 중 오류 발생: {str(e)}")
        return None

def audit_dns_service():
    """Audit DNS service settings and save results in a JSON file."""
    computer_name = os.getenv('COMPUTERNAME', 'UNKNOWN_PC')
    raw_dir, result_dir = setup_directories(computer_name)

    is_safe = check_dns_service()
    diagnosis = "양호" if is_safe else "경고"
    status = "DNS 서비스가 활성화되어 있으나 동적 업데이트 권한이 설정되어 있지 않은 경우, 이는 안전합니다." if is_safe else "DNS 서비스가 활성화되어 있으나 동적 업데이트 권한이 설정되어 있는 경우, 이는 위험합니다."

    results = {
        "분류": "서비스관리",
        "코드": "W-49",
        "위험도": "상",
        "진단 항목": "DNS 서비스 구동 점검",
        "진단 결과": diagnosis,
        "현황": [status],
        "대응방안": "DNS 서비스 구동 점검"
    }

    # Save results to a JSON file
    json_path = os.path.join(result_dir, f"W-49_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    if not check_admin():
        # Restart the script with admin rights if not running as admin
        subprocess.call(['powershell', 'Start-Process', 'python', f'"{os.path.abspath(__file__)}"', '-Verb', 'RunAs'])
    else:
        audit_dns_service()
