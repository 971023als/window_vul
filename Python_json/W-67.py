import os
import json
import subprocess
from winreg import ConnectRegistry, OpenKey, QueryValueEx, HKEY_LOCAL_MACHINE

def check_admin_rights():
    """ Check if the script is run as an administrator. """
    try:
        return os.getuid() == 0
    except AttributeError:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin() != 0

def setup_directories(computer_name):
    """ Prepare directories for storing results. """
    raw_dir = f"C:\\Window_{computer_name}_raw"
    result_dir = f"C:\\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def check_policy_settings():
    """ Check the system policy settings related to anonymous enumeration. """
    registry = ConnectRegistry(None, HKEY_LOCAL_MACHINE)
    lsa_key_path = r"SYSTEM\CurrentControlSet\Control\LSA"
    try:
        with OpenKey(registry, lsa_key_path) as key:
            restrict_anonymous = QueryValueEx(key, "restrictanonymous")[0]
            restrict_anonymous_sam = QueryValueEx(key, "RestrictAnonymousSAM")[0]
            if restrict_anonymous == 1 and restrict_anonymous_sam == 1:
                return "양호", ["익명 SAM 계정 접근을 제한하는 설정이 적절히 구성되었습니다."]
            else:
                return "취약", ["익명 SAM 계정 접근을 제한하는 설정이 적절히 구성되지 않았습니다."]
    except FileNotFoundError:
        return "취약", ["레지스트리 설정을 확인할 수 없습니다."]

def main():
    if not check_admin_rights():
        print("이 스크립트는 관리자 권한으로 실행되어야 합니다.")
        return
    
    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_directories(computer_name)
    
    diagnosis_result, status_messages = check_policy_settings()
    
    result = {
        "분류": "보안관리",
        "코드": "W-68",
        "위험도": "상",
        "진단 항목": "SAM 파일 접근 통제 설정",
        "진단 결과": diagnosis_result,
        "현황": status_messages,
        "대응방안": "익명 열거를 허용하지 않도록 시스템 정책을 설정"
    }
    
    json_path = os.path.join(result_dir, f"W-68_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
