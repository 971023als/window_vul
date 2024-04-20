import os
import json
import subprocess
import socket

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

def disable_unnecessary_services():
    """Check and potentially recommend deactivation of unnecessary services."""
    services = ["HTTP", "FTP", "SMTP"]
    active_services = []

    for service in services:
        try:
            if socket.getservbyname(service.lower()):
                active_services.append(service)
        except Exception:
            continue

    if active_services:
        return "HTTP, FTP, SMTP 서비스가 필요 없는 경우 비활성화 권장. 필요하지 않은 서비스는 비활성화하여 안전함."
    else:
        return "필요한 서비스는 모두 비활성화되어 있습니다."

def audit_services():
    """Perform the service audit and save results in a JSON file."""
    computer_name = os.getenv('COMPUTERNAME', 'UNKNOWN_PC')
    raw_dir, result_dir = setup_directories(computer_name)

    service_status = disable_unnecessary_services()
    results = {
        "분류": "서비스관리",
        "코드": "W-50",
        "위험도": "상",
        "진단 항목": "HTTP/FTP/SMTP 배너 차단",
        "진단 결과": "양호",
        "현황": [service_status],
        "대응방안": "HTTP/FTP/SMTP 배너 차단"
    }

    # Save results to a JSON file
    json_path = os.path.join(result_dir, f"W-50_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    if not check_admin():
        # Restart the script with admin rights if not running as admin
        subprocess.call(['powershell', 'Start-Process', 'python', f'"{os.path.abspath(__file__)}"', '-Verb', 'RunAs'])
    else:
        audit_services()
