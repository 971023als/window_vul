import os
import json
import subprocess

def check_admin_rights():
    """ Check if the script is run as administrator. """
    try:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin()
    except Exception as e:
        return False

def setup_directories(computer_name):
    """ Prepare directories for storing results. """
    raw_dir = f"C:\\Windows_{computer_name}_raw"
    result_dir = f"C:\\Windows_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def check_bitlocker_status():
    """ Check BitLocker status for the C: drive. """
    try:
        result = subprocess.run(['manage-bde', '-status', 'C:'], capture_output=True, text=True)
        if 'Protection On' in result.stdout:
            return True, "C 드라이브가 BitLocker로 암호화되어 있습니다."
        else:
            return False, "C 드라이브가 BitLocker로 암호화되어 있지 않습니다."
    except subprocess.CalledProcessError:
        return False, "BitLocker 상태 확인 실패."

def main():
    if not check_admin_rights():
        print("이 스크립트는 관리자 권한으로 실행되어야 합니다.")
        return
    
    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_directories(computer_name)
    
    encrypted, status_message = check_bitlocker_status()
    
    result = {
        "분류": "보안관리",
        "코드": "W-71",
        "위험도": "상",
        "진단 항목": "디스크볼륨 암호화 설정",
        "진단 결과": "양호" if encrypted else "취약",
        "현황": [status_message],
        "대응방안": "디스크볼륨 암호화 설정을 통한 데이터 보호 강화"
    }
    
    json_path = os.path.join(result_dir, f"W-71_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
