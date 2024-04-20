import os
import json
import subprocess
from pathlib import Path
import shutil

# Initialize diagnostics JSON object
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-33",
    "위험도": "상",
    "진단 항목": "해독 가능한 암호화를 사용하여 암호 저장",
    "진단 결과": "양호",  # Presuming "Good" as the default value
    "현황": [],
    "대응방안": "Implement encryption that cannot be decrypted to store passwords"
}

# Check and request administrator privileges
def check_admin_privileges():
    if not os.getuid() == 0:
        print("Administrator privileges are required...")
        subprocess.call(['sudo', 'python3'] + sys.argv)
        exit()

# Prepare environment
def prepare_environment(computer_name, raw_dir, result_dir):
    shutil.rmtree(raw_dir, ignore_errors=True)
    shutil.rmtree(result_dir, ignore_errors=True)
    os.makedirs(raw_dir)
    os.makedirs(result_dir)
    subprocess.run(['secedit', '/export', '/cfg', f'{raw_dir}\\Local_Security_Policy.txt'], capture_output=True)
    Path(f"{raw_dir}\\compare.txt").touch()
    with open(f"{raw_dir}\\install_path.txt", 'w') as f:
        f.write(str(Path.cwd()))
    with open(f"{raw_dir}\\systeminfo.txt", 'w') as f:
        subprocess.run(['systeminfo'], stdout=f)

# Analyze IIS configuration
def analyze_iis_configuration(raw_dir, result_dir, computer_name):
    application_host_config_path = Path(os.environ['WINDIR']) / 'System32' / 'Inetsrv' / 'Config' / 'applicationHost.Config'
    if application_host_config_path.exists():
        application_host_config = application_host_config_path.read_text()
        with open(f"{raw_dir}\\iis_setting.txt", 'w') as file:
            file.write(application_host_config)

        unsupported_extensions = [".htr", ".idc", ".stm", ".shtm", ".shtml", ".printer", ".htw", ".ida", ".idq"]
        found_extensions = [line for line in application_host_config.split('\n') if any(ext in line for ext in unsupported_extensions)]
        
        if found_extensions:
            diagnosis_result["현황"].append("Unsupported extensions found posing a security risk.")
            diagnosis_result["진단 결과"] = "취약"
            with open(f"{result_dir}\\W-Window-{computer_name}.txt", 'w') as file:
                file.writelines(found_extensions)
        else:
            diagnosis_result["현황"].append("No unsupported extensions found, complying with security standards.")

# Main execution
computer_name = os.environ.get('COMPUTERNAME', 'UNKNOWN_PC')
raw_dir = Path(f"C:\\Window_{computer_name}_raw")
result_dir = Path(f"C:\\Window_{computer_name}_result")

check_admin_privileges()
prepare_environment(computer_name, raw_dir, result_dir)
analyze_iis_configuration(raw_dir, result_dir, computer_name)

# Save JSON results to a file
json_file_path = result_dir / f'W-33.json'
with open(json_file_path, 'w') as file:
    json.dump(diagnosis_result, file, ensure_ascii=False, indent=4)

print("Script execution completed.")
