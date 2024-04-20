import os
import json
import subprocess

def check_admin():
    """Check if the script is run as an administrator."""
    try:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
    except:
        return False

def setup_directories(computer_name):
    """Create directories for storing raw data and results."""
    raw_dir = fr"C:\Window_{computer_name}_raw"
    result_dir = fr"C:\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def analyze_sam_permissions():
    """Check the SAM file permissions and return findings."""
    sam_path = os.getenv("SYSTEMROOT") + r"\system32\config\SAM"
    cmd = f'icacls "{sam_path}"'
    result = subprocess.run(cmd, capture_output=True, text=True, shell=True)
    permissions = result.stdout

    if 'Administrator' in permissions and 'System' in permissions and 'Everyone' not in permissions:
        return True, "Administrator 및 System 그룹 권한만이 SAM 파일에 설정되어 있습니다."
    else:
        return False, "Administrator 또는 System 그룹 외 다른 권한이 SAM 파일에 대해 발견되었습니다."

def main():
    if not check_admin():
        print("이 스크립트는 관리자 권한으로 실행되어야 합니다.")
        return

    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_directories(computer_name)

    is_secure, details = analyze_sam_permissions()
    results = {
        "분류": "보안관리",
        "코드": "W-63",
        "위험도": "상",
        "진단 항목": "SAM 파일 접근 통제 설정",
        "진단 결과": "양호" if is_secure else "취약",
        "현황": [details],
        "대응방안": "원격으로 액세스할 수 있는 레지스트리 경로 차단"
    }

    # Save results to a JSON file
    json_path = os.path.join(result_dir, f"W-63_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as file:
        json.dump(results, file, ensure_ascii=False, indent=4)

    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
