import os
import json
import subprocess
from win32serviceutil import QueryServiceStatus, SERVICE_RUNNING
import winreg

def check_admin():
    """Check if the script is running as administrator."""
    try:
        return os.getuid() == 0
    except AttributeError:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin() != 0

def setup_directories(computer_name):
    """Setup directories for storing raw and result data."""
    raw_dir = f"C:\\Window_{computer_name}_raw"
    result_dir = f"C:\\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def query_telnet_service():
    """Check the Telnet service configuration using Windows registry."""
    try:
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Services\TlntSvr") as key:
            config = winreg.QueryValueEx(key, "ImagePath")
            return config
    except FileNotFoundError:
        return None

def check_telnet_security():
    """Check the security settings of the Telnet service."""
    # Query the service status
    status = QueryServiceStatus('TlntSvr')
    if status and status[1] == SERVICE_RUNNING:
        config = query_telnet_service()
        if config and "NTLM" in config:
            return True, "Telnet 서비스가 안전한 NTLM 인증 방식을 사용하고 있습니다."
        else:
            return False, "Telnet 서비스가 안전하지 않은 인증 방식을 사용하고 있습니다. NTLM을 사용하고 비밀번호를 피하도록 권장됩니다."
    else:
        return None, "Telnet 서비스가 실행되지 않거나 설치되지 않았으며, 이는 안전으로 간주됩니다."

def main():
    if not check_admin():
        print("This script requires administrative privileges.")
        return

    computer_name = os.getenv('COMPUTERNAME', 'UNKNOWN_PC')
    raw_dir, result_dir = setup_directories(computer_name)

    is_secure, message = check_telnet_security()
    results = {
        "분류": "서비스관리",
        "코드": "W-51",
        "위험도": "상",
        "진단 항목": "Telnet 보안 설정",
        "진단 결과": "양호" if is_secure else "취약",
        "현황": [message],
        "대응방안": "Telnet 보안 설정"
    }

    # Save results to a JSON file
    json_path = os.path.join(result_dir, f"W-51_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
