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

def check_audit_settings(raw_dir):
    """Check the audit settings from the local security policy."""
    audit_settings = [
        "AuditLogonEvents", "AuditPrivilegeUse", "AuditPolicyChange",
        "AuditDSAccess", "AuditAccountLogon", "AuditAccountManage"
    ]
    incorrectly_configured = False
    settings_status = []

    # Normally you would retrieve this information from the system, but for illustration,
    # let's assume it's already in a file.
    security_settings_path = os.path.join(raw_dir, "Local_Security_Policy.txt")
    with open(security_settings_path, 'r') as file:
        security_settings = file.read()
    
    for setting in audit_settings:
        if f"{setting}.*0" in security_settings:
            incorrectly_configured = True
            settings_status.append(f"{setting}: No Auditing")
    
    return incorrectly_configured, settings_status

def main():
    if not is_admin():
        print("이 스크립트는 관리자 권한으로 실행되어야 합니다.")
        return
    
    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_directories(computer_name)
    
    incorrectly_configured, settings_status = check_audit_settings(raw_dir)
    
    results = {
        "분류": "로그관리",
        "코드": "W-57",
        "위험도": "상",
        "진단 항목": "정책에 따른 시스템 로깅 설정",
        "진단 결과": "양호" if not incorrectly_configured else "취약",
        "현황": settings_status if incorrectly_configured else ["All audit events are correctly configured."],
        "대응방안": "정책에 따른 시스템 로깅 설정"
    }

    # Save the results to a JSON file
    json_path = os.path.join(result_dir, f"W-57_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as file:
        json.dump(results, file, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
