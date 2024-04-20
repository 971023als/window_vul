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
        return ctypes.windll.shell32.IsUserAnAdmin() != 0

def setup_directories(computer_name):
    """ Setup directories for storing results. """
    raw_dir = f"C:\\Window_{computer_name}_raw"
    result_dir = f"C:\\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def export_local_security_policy(raw_dir):
    """ Export local security policies to a text file. """
    output_path = os.path.join(raw_dir, "Local_Security_Policy.txt")
    subprocess.run(['secedit', '/export', '/cfg', output_path], check=True)
    return output_path

def check_session_settings():
    """ Check the registry for session disconnection settings. """
    try:
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"System\CurrentControlSet\Services\LanManServer\Parameters") as key:
            enable_forced_log_off = winreg.QueryValueEx(key, "EnableForcedLogOff")[0]
            auto_disconnect = winreg.QueryValueEx(key, "AutoDisconnect")[0]
            return enable_forced_log_off, auto_disconnect
    except FileNotFoundError:
        return None, None

def main():
    if not check_admin_rights():
        print("이 스크립트는 관리자 권한으로 실행되어야 합니다.")
        return
    
    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_directories(computer_name)
    export_local_security_policy(raw_dir)
    enable_forced_log_off, auto_disconnect = check_session_settings()
    
    result = {
        "분류": "보안관리",
        "코드": "W-74",
        "위험도": "상",
        "진단 항목": "세션 연결을 중단하기 전에 필요한 유휴시간",
        "진단 결과": "양호" if enable_forced_log_off == 1 and auto_disconnect == 15 else "취약",
        "현황": ["서버에서 강제 로그오프 및 자동 연결 끊김이 적절하게 설정되었습니다."] if enable_forced_log_off == 1 and auto_disconnect == 15 else ["서버에서 강제 로그오프 및 자동 연결 끊김 설정이 적절하지 않습니다."],
        "대응방안": "세션 연결을 중단하기 전에 필요한 유휴시간 설정 조정"
    }
    
    json_path = os.path.join(result_dir, f"W-74_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
