import os
import json
import subprocess
from pathlib import Path
import shutil

# Initialize diagnostics JSON object
audit_params = {
    "Category": "Account Management",
    "Code": "W-34",
    "RiskLevel": "High",
    "AuditItem": "Use of decryptable encryption for password storage",
    "AuditResult": "Good",  # Assuming good as the default state
    "CurrentStatus": [],
    "Mitigation": "Use of non-decryptable encryption for password storage"
}

# Check and request administrator privileges
def check_admin_privileges():
    if not os.getuid() == 0:
        print("Administrator privileges are required...")
        subprocess.call(['sudo', 'python3'] + sys.argv)
        exit()

# Prepare environment
def initialize_environment(computer_name, raw_dir, result_dir):
    print("Setting up the environment...")
    shutil.rmtree(raw_dir, ignore_errors=True)
    shutil.rmtree(result_dir, ignore_errors=True)
    os.makedirs(raw_dir)
    os.makedirs(result_dir)

    subprocess.run(['secedit', '/export', '/cfg', f'{raw_dir}\\Local_Security_Policy.txt'], capture_output=True)
    (Path(raw_dir) / 'compare.txt').touch()
    with open(Path(raw_dir) / 'systeminfo.txt', 'w') as f:
        subprocess.run(['systeminfo'], stdout=f)

# Analyze IIS configuration
def analyze_iis_configuration(raw_dir):
    print("Analyzing IIS Settings...")
    application_host_config_path = Path(os.environ['WINDIR']) / 'System32' / 'Inetsrv' / 'Config' / 'applicationHost.Config'
    if application_host_config_path.exists():
        application_host_config = application_host_config_path.read_text()
        with open(Path(raw_dir) / 'iis_setting.txt', 'w') as f:
            f.write(application_host_config)

        # Detect if the server is using IIS 5.0 or below, which is deprecated
        if "IIS5" in application_host_config:
            audit_params["CurrentStatus"].append("Deprecated IIS version detected. Upgrade required.")
            audit_params["AuditResult"] = "Vulnerable"
        else:
            audit_params["CurrentStatus"].append("No deprecated IIS version detected. Compliant with security standards.")

# Main execution
computer_name = os.environ.get('COMPUTERNAME', 'UNKNOWN_PC')
raw_dir = f"C:\\Window_{computer_name}_raw"
result_dir = f"C:\\Window_{computer_name}_result"

check_admin_privileges()
initialize_environment(computer_name, raw_dir, result_dir)
analyze_iis_configuration(raw_dir)

# Save JSON results to a file
json_file_path = Path(result_dir) / 'W-34.json'
with open(json_file_path, 'w') as file:
    json.dump(audit_params, file, indent=4)

print("Script execution completed.")
