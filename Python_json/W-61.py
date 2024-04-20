import os
import json
import subprocess
import win32security
import win32con

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

def check_directory_permissions(directories):
    """Check directory permissions for vulnerabilities."""
    vulnerability_found = False
    results = []
    for directory in directories:
        try:
            security_info = win32security.GetFileSecurity(directory, win32security.DACL_SECURITY_INFORMATION)
            dacl = security_info.GetSecurityDescriptorDacl()
            for i in range(0, dacl.GetAceCount()):
                ace = dacl.GetAce(i)
                sid = ace[2]
                name, domain, type = win32security.LookupAccountSid(None, sid)
                if name.lower() == "everyone":
                    vulnerability_found = True
                    results.append(f"취약: Everyone 그룹 권한이 발견되었습니다. - {directory}")
                    break
        except Exception as e:
            results.append(str(e))

    if not vulnerability_found:
        results.append("안전: Everyone 그룹 권한이 발견되지 않았습니다.")

    return vulnerability_found, results

def main():
    if not check_admin():
        print("이 스크립트는 관리자 권한으로 실행되어야 합니다.")
        return

    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_directories(computer_name)

    directories = [r"C:\Windows\System32\LogFiles", r"C:\Windows\System32\Config"]
    vulnerability_found, check_results = check_directory_permissions(directories)

    results = {
        "분류": "로그관리",
        "코드": "W-61",
        "위험도": "상",
        "진단 항목": "원격에서 이벤트 로그 파일 접근 차단",
        "진단 결과": "취약" if vulnerability_found else "양호",
        "현황": check_results,
        "대응방안": "원격으로 액세스할 수 있는 레지스트리 경로 차단"
    }

    # Save results to a JSON file
    json_path = os.path.join(result_dir, f"W-61_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as file:
        json.dump(results, file, ensure_ascii=False, indent=4)

    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
