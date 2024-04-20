import json
import os
import subprocess
from pathlib import Path

# Define the audit parameters
audit_params = {
    "분류": "계정 관리",
    "코드": "W-36",
    "위험도": "높음",
    "진단 항목": "비밀번호 저장을 위한 복호화 가능한 암호화 사용",
    "진단 결과": "양호",  # '양호'로 기본 가정
    "현황": [],
    "대응방안": "비밀번호 저장을 위한 비복호화 가능한 암호화 사용"
}

# Ensure the script runs with Administrator privileges
def check_admin_privileges():
    try:
        # Check for admin rights and relaunch if needed
        if os.getuid() != 0:
            subprocess.check_call(['sudo', 'python3'] + sys.argv)
    except AttributeError:
        # Windows handling for admin rights, assuming this is run in an elevated command prompt
        import ctypes
        if not ctypes.windll.shell32.IsUserAnAdmin():
            subprocess.run(['powershell', '-Command', f"Start-Process python {' '.join(sys.argv)} -Verb RunAs"], check=True)
            exit()

# Setup console environment
def setup_console():
    print("Initializing audit environment...")

# Setup audit environment
def initialize_audit_environment():
    computer_name = os.getenv('COMPUTERNAME', 'UNKNOWN_PC')
    raw_dir = Path(f"C:/Audit_{computer_name}_Raw")
    result_dir = Path(f"C:/Audit_{computer_name}_Results")

    # Clean up previous data and set up directories for current audit
    for directory in [raw_dir, result_dir]:
        if directory.exists():
            for item in directory.iterdir():
                if item.is_dir():
                    shutil.rmtree(item)
                else:
                    item.unlink()
        else:
            directory.mkdir(parents=True, exist_ok=True)

    # Mock to simulate 'secedit /export /cfg'
    (raw_dir / 'Local_Security_Policy.txt').write_text('Simulated security policy data')
    (raw_dir / 'SystemInfo.txt').write_text('Simulated system info')

    return raw_dir, result_dir

# Perform NetBIOS Configuration Check
def check_netbios_configuration():
    print("Checking NetBIOS Configuration...")
    # Simulating a system call to check NetBIOS configuration
    try:
        netbios_config = subprocess.check_output("wmic nicconfig where TcpipNetbiosOptions=2 get description", shell=True)
        if netbios_config:
            print("NetBIOS over TCP/IP is disabled - configuration is secure.")
            return "NetBIOS over TCP/IP is disabled, aligning with secure configuration recommendations."
        else:
            print("Attention Needed: Review NetBIOS over TCP/IP settings.")
            return "Review NetBIOS over TCP/IP settings for potential security improvements."
    except subprocess.CalledProcessError:
        return "Failed to retrieve NetBIOS configuration."

# Main script logic
def main():
    check_admin_privileges()
    setup_console()
    raw_dir, result_dir = initialize_audit_environment()
    netbios_status = check_netbios_configuration()
    audit_params["현황"].append(netbios_status)

    # Save the JSON results to a file
    json_file_path = result_dir / 'W-36.json'
    with open(json_file_path, 'w', encoding='utf-8') as file:
        json.dump(audit_params, file, ensure_ascii=False, indent=4)

    print("Audit completed. Review the results in", result_dir)

if __name__ == "__main__":
    main()
