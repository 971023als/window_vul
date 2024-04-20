import os
import json
import subprocess
import winreg

def check_admin_rights():
    """ Check if the script is run with administrator privileges. """
    try:
        return os.getuid() == 0
    except AttributeError:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin()

def setup_directories(computer_name):
    """ Setup directories for storing results. """
    raw_dir = f"C:\\Windows_{computer_name}_raw"
    result_dir = f"C:\\Windows_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def check_dos_defense():
    """ Check the SynAttackProtect registry setting. """
    try:
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE,
                            r"SYSTEM\CurrentControlSet\Services\Tcpip\Parameters") as key:
            syn_attack_protect = winreg.QueryValueEx(key, "SynAttackProtect")[0]
            return syn_attack_protect == 1
    except FileNotFoundError:
        return False

def main():
    if not check_admin_rights():
        print("이 스크립트는 관리자 권한으로 실행되어야 합니다.")
        return
    
    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_directories(computer_name)
    
    syn_attack_protect_enabled = check_dos_defense()
    
    result = {
        "분류": "보안관리",
        "코드": "W-72",
        "위험도": "상",
        "진단 항목": "Dos공격 방어 레지스트리 설정",
        "진단 결과": "양호" if syn_attack_protect_enabled else "취약",
        "현황": ["SynAttackProtect가 활성화되어 DoS 공격 방어 설정이 강화되었습니다."] if syn_attack_protect_enabled else ["SynAttackProtect가 비활성화되어 있거나, 설정이 적절히 조정되지 않았습니다."],
        "대응방안": "원격 시스템에서 강제로 시스템 종료 정책을 적절히 설정"
    }
    
    json_path = os.path.join(result_dir, f"W-72_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
