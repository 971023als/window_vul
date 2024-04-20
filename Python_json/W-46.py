import os
import json
import subprocess
import win32serviceutil

def check_admin():
    """Check if the script is running as an administrator."""
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

def check_snmp_service():
    """Check the SNMP service status."""
    try:
        status = win32serviceutil.QueryServiceStatus("SNMP")[1]
        return status == win32serviceutil.SERVICE_RUNNING
    except Exception as e:
        print(f"SNMP 서비스 상태 검사 중 오류 발생: {str(e)}")
        return None

def audit_snmp_service():
    """Audit the SNMP service and save results to a JSON file."""
    computer_name = os.getenv('COMPUTERNAME', 'UNKNOWN_PC')
    raw_dir, result_dir = setup_directories(computer_name)

    snmp_active = check_snmp_service()

    results = {
        "분류": "서비스관리",
        "코드": "W-46",
        "위험도": "상",
        "진단 항목": "SNMP 서비스 구동 점검",
        "진단 결과": "경고" if snmp_active else "양호",
        "현황": ["SNMP 서비스가 활성화되어 있습니다. 이는 보안상 위험할 수 있으므로, 필요하지 않은 경우 비활성화하는 것이 권장됩니다."] if snmp_active else ["SNMP 서비스가 실행되지 않고 있습니다. 이는 추가 보안을 위한 긍정적인 상태입니다."],
        "대응방안": "SNMP 서비스 구동 점검"
    }

    # Save results to a JSON file
    json_path = os.path.join(result_dir, f"W-46_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    if not check_admin():
        # Restart the script with admin rights if not running as admin
        subprocess.call(['powershell', 'Start-Process', 'python', f'"{os.path.abspath(__file__)}"', '-Verb', 'RunAs'])
    else:
        audit_snmp_service()
