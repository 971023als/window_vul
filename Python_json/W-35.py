import os
import json
import subprocess
from pathlib import Path
import shutil
import codecs

# Initialize audit parameters
audit_parameters = {
    "분류": "계정 관리",
    "코드": "W-35",
    "위험도": "높음",
    "진단 항목": "비밀번호 저장을 위한 복호화 가능한 암호화 사용",
    "진단 결과": "양호",  # "양호"를 기본 상태로 가정
    "현황": [],
    "대응방안": "비밀번호 저장을 위한 비복호화 가능한 암호화 사용"
}

# Check and request administrator privileges
def check_admin_privileges():
    if not os.getuid() == 0:
        print("관리자 권한이 필요합니다...")
        subprocess.call(['sudo', 'python3'] + sys.argv)
        exit()

# Set console environment and prepare audit environment
def setup_audit_environment():
    computer_name = os.environ.get('COMPUTERNAME', 'UNKNOWN_PC')
    raw_dir = Path(f"C:\\Audit_{computer_name}_RawData")
    result_dir = Path(f"C:\\Audit_{computer_name}_Results")
    
    # Cleanup previous data and prepare new directories
    shutil.rmtree(raw_dir, ignore_errors=True)
    shutil.rmtree(result_dir, ignore_errors=True)
    os.makedirs(raw_dir)
    os.makedirs(result_dir)
    
    # Export local security policy and save system information
    subprocess.run(['secedit', '/export', '/cfg', str(raw_dir / 'Local_Security_Policy.txt')])
    with open(raw_dir / 'SystemInfo.txt', 'w') as sys_info_file:
        subprocess.run(['systeminfo'], stdout=sys_info_file)

    return raw_dir, result_dir

# Perform WebDAV Security Check
def perform_webdav_security_check(raw_dir):
    print("WebDAV 보안 점검을 수행 중...")
    service_status = subprocess.getoutput("sc query W3SVC")
    
    if "RUNNING" in service_status:
        application_host_config = Path(os.environ['WINDIR']) / 'System32' / 'inetsrv' / 'config' / 'applicationHost.config'
        if application_host_config.exists():
            content = application_host_config.read_text()
            if "webdav" in content.lower():
                with open(raw_dir / 'WebDAVConfigDetails.txt', 'w', encoding='utf-8') as f:
                    f.write(content)
                print("점검 필요: WebDAV 구성이 발견되었습니다. 자세한 내용은 WebDAVConfigDetails.txt 파일을 참조하세요.")
            else:
                print("조치 필요 없음: WebDAV가 적절하게 구성되었거나 존재하지 않습니다.")
        else:
            print("IIS 구성 파일을 찾을 수 없습니다.")
    else:
        print("조치 필요 없음: IIS 웹 게시 서비스가 실행되지 않고 있습니다.")

# Main script execution
check_admin_privileges()
raw_dir, result_dir = setup_audit_environment()
perform_webdav_security_check(raw_dir)

# Save JSON results to a file
json_file_path = result_dir / 'W-35.json'
with codecs.open(json_file_path, 'w', 'utf-8-sig') as file:
    json.dump(audit_parameters, file, ensure_ascii=False, indent=4)

print("스크립트 실행 완료.")
