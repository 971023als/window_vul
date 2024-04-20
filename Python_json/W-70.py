import os
import json
import subprocess
import winreg

def check_admin_rights():
    """ Check if the script is run as administrator. """
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

def export_security_policy(raw_dir):
    """ Export local security settings to a text file. """
    output_file = os.path.join(raw_dir, "Local_Security_Policy.txt")
    subprocess.run(["secedit", "/export", "/cfg", output_file], check=True)
    return output_file

def analyze_security_policy(file_path):
    """ Analyze the local security policy from an exported file. """
    with open(file_path, 'r', encoding='utf-16') as file:
        settings = file.read()

    allocate_dasd = "AllocateDASD" in settings and "=0" in settings
    return not allocate_dasd  # Return True if vulnerable

def main():
    if not check_admin_rights():
        print("관리자 권한으로 스크립트를 실행해야 합니다.")
        return
    
    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_directories(computer_name)
    
    policy_file = export_security_policy(raw_dir)
    is_vulnerable = analyze_security_policy(policy_file)
    
    result = {
        "분류": "보안관리",
        "코드": "W-70",
        "위험도": "상",
        "진단 항목": "이동식 미디어 포맷 및 꺼내기 허용",
        "진단 결과": "취약" if is_vulnerable else "양호",
        "현황": ["디스크 할당 권한 변경이 관리자만 가능하도록 설정되지 않았습니다."] if is_vulnerable else ["디스크 할당 권한 변경이 관리자만 가능하도록 설정되어 있는 상태입니다."],
        "대응방안": "이동식 미디어의 포맷 및 꺼내기를 적절히 제어"
    }
    
    json_path = os.path.join(result_dir, f"W-70_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
