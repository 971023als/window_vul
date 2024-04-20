import os
import json
import subprocess
import winreg
from win32com.shell import shell

def check_admin():
    """Check if the script is running as an administrator."""
    return shell.IsUserAnAdmin()

def setup_directories(computer_name):
    """Setup directories for storing raw and result data."""
    raw_dir = f"C:\\Window_{computer_name}_raw"
    result_dir = f"C:\\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def check_iis_custom_error_page_setup(raw_dir):
    """Check the IIS configuration for custom error page settings."""
    config_file_path = os.path.join(raw_dir, "web.config")
    if not os.path.exists(config_file_path):
        print("web.config 파일을 찾을 수 없습니다.")
        return None

    with open(config_file_path, 'r', encoding='utf-8') as file:
        config_lines = file.readlines()

    custom_error_settings = any("error statusCode" in line or "SystemDrive" in line for line in config_lines)
    return custom_error_settings

def audit_iis_web_service():
    """Audit the IIS Web Service for custom error page settings."""
    computer_name = os.getenv('COMPUTERNAME', 'UNKNOWN_PC')
    raw_dir, result_dir = setup_directories(computer_name)

    custom_error_settings = check_iis_custom_error_page_setup(raw_dir)

    results = {
        "분류": "서비스관리",
        "코드": "W-45",
        "위험도": "상",
        "진단 항목": "IIS 웹서비스 정보 숨김",
        "진단 결과": "양호" if custom_error_settings else "취약",
        "현황": ["IIS 커스텀 에러 페이지 설정이 적절하게 구성되어 보안이 강화되었습니다."] if custom_error_settings else ["IIS 커스텀 에러 페이지 설정이 적절하지 않아 보안에 취약할 수 있습니다."],
        "대응방안": "IIS 웹서비스 정보 숨김"
    }

    # Save results to a JSON file
    json_path = os.path.join(result_dir, f"W-45_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    if not check_admin():
        # Restart the script with admin rights if not running as admin
        subprocess.call(['powershell', 'Start-Process', 'python', f'"{os.path.abspath(__file__)}"', '-Verb', 'RunAs'])
    else:
        audit_iis_web_service()
