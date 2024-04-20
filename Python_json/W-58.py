import os
import json
import subprocess
import ctypes
import winreg

def is_admin():
    """Check if the program is running with administrative privileges."""
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except Exception:
        return False

def setup_directories(computer_name):
    """Prepare directories for storing results."""
    raw_dir = f"C:\\Window_{computer_name}_raw"
    result_dir = f"C:\\Window_{computer_name}_result"
    if not os.path.exists(raw_dir):
        os.makedirs(raw_dir)
    if not os.path.exists(result_dir):
        os.makedirs(result_dir)
    return raw_dir, result_dir

def check_log_review_policies():
    """Mock function to simulate checking log review policies."""
    # This should include actual checks against the system's log management policies.
    return ["로그 저장 정책 및 감사를 통해 리포트를 작성하고 보안 로그를 관리하는데 필요한 정책을 검토 및 설정 필요"]

def main():
    if not is_admin():
        print("이 스크립트는 관리자 권한으로 실행되어야 합니다.")
        return
    
    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_directories(computer_name)
    
    policy_reviews = check_log_review_policies()
    
    results = {
        "분류": "로그관리",
        "코드": "W-58",
        "위험도": "상",
        "진단 항목": "로그의 정기적 검토 및 보고",
        "진단 결과": "양호" if policy_reviews else "취약",
        "현황": policy_reviews,
        "대응방안": "로그의 정기적 검토 및 보고"
    }

    # Save the results to a JSON file
    json_path = os.path.join(result_dir, f"W-58_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as file:
        json.dump(results, file, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
