import os
import json
import subprocess
from win32serviceutil import QueryServiceStatus, StopService, RemoveService
from win32api import CloseHandle

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

def audit_rds_status():
    import win32service
    audit_result = {
        "분류": "계정관리",
        "코드": "W-42",
        "위험도": "상",
        "진단항목": "RDS(RemoteDataServices)제거",
        "진단결과": "양호",  # 기본 값을 "양호"로 가정
        "현황": [],
        "대응방안": "RDS(RemoteDataServices)제거"
    }

    try:
        hscm = win32service.OpenSCManager(None, None, win32service.SC_MANAGER_ALL_ACCESS)
        hs = win32service.OpenService(hscm, 'W3SVC', win32service.SERVICE_ALL_ACCESS)
        status = win32service.QueryServiceStatus(hs)[1]
        if status == win32service.SERVICE_RUNNING:
            audit_result["진단결과"] = "위험"
            audit_result["현황"].append("웹 서비스가 실행 중입니다. RDS(Remote Data Services)가 활성화되어 있을 수 있습니다.")
            audit_result["대응방안"] = "웹 서비스를 비활성화하거나 RDS 관련 구성을 제거하세요."
        else:
            audit_result["현황"].append("웹 서비스가 실행되지 않거나 설치되지 않았습니다. RDS 제거 상태가 양호합니다.")
        CloseHandle(hs)
        CloseHandle(hscm)
    except Exception as e:
        audit_result["진단결과"] = "오류"
        audit_result["현황"].append(str(e))

    return audit_result

def save_results(audit_result, result_dir):
    file_path = os.path.join(result_dir, "W-42_diagnostics_results.json")
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(audit_result, f, ensure_ascii=False, indent=4)

if __name__ == "__main__":
    if not check_admin():
        subprocess.call(['powershell', 'Start-Process', 'python', f'"{os.path.abspath(__file__)}"', '-Verb', 'RunAs'])
    else:
        computer_name = os.getenv('COMPUTERNAME', 'UNKNOWN_PC')
        raw_dir, result_dir = setup_directories(computer_name)
        audit_result = audit_rds_status()
        save_results(audit_result, result_dir)
        print(f"결과가 {result_dir}에 저장되었습니다.")
