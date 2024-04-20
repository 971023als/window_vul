import os
import json
import subprocess
from pathlib import Path
import shutil
import stat

# JSON 객체 초기화
diagnosis_result = {
    "분류": "서비스관리",
    "코드": "W-24",
    "위험도": "상",
    "진단항목": "IIS CGI 실행 제한",
    "진단결과": "양호",  # 기본 값을 "양호"로 가정
    "현황": [],
    "대응방안": "IIS CGI 실행 제한"
}

# 관리자 권한 확인 및 요청
if not os.getuid() == 0:
    print("관리자 권한이 필요합니다...")
    subprocess.call(['sudo', 'python3'] + sys.argv)
    sys.exit()

# 초기 설정
computer_name = os.environ['COMPUTERNAME']
raw_dir = Path(f"C:\\Window_{computer_name}_raw")
result_dir = Path(f"C:\\Window_{computer_name}_result")

# 디렉터리 초기화
shutil.rmtree(raw_dir, ignore_errors=True)
shutil.rmtree(result_dir, ignore_errors=True)
raw_dir.mkdir(parents=True, exist_ok=True)
result_dir.mkdir(parents=True, exist_ok=True)

# 보안 설정 및 시스템 정보 수집
subprocess.run(['secedit', '/export', '/cfg', str(raw_dir / "Local_Security_Policy.txt")])
with open(raw_dir / 'install_path.txt', 'w') as f:
    f.write(str(raw_dir))
with open(raw_dir / 'systeminfo.txt', 'w') as f:
    subprocess.run(['systeminfo'], stdout=f)

# IIS 설정 분석
application_host_config_path = Path(os.environ['WINDIR']) / 'System32' / 'Inetsrv' / 'Config' / 'applicationHost.Config'
with open(application_host_config_path) as file:
    content = file.read()
with open(raw_dir / 'iis_setting.txt', 'w') as file:
    file.write(content)

# 폴더 권한 감사
service_status = subprocess.run(['sc', 'query', 'W3SVC'], text=True, capture_output=True)
is_running = "RUNNING" in service_status.stdout
folders_to_check = [Path("C:/inetpub/scripts"), Path("C:/inetpub/cgi-bin")]
has_permission_issue = False

if is_running:
    for folder in folders_to_check:
        if folder.exists():
            acl_output = subprocess.check_output(['icacls', str(folder)], text=True)
            if "Everyone:(M)" in acl_output or "Everyone:(F)" in acl_output:
                has_permission_issue = True
                diagnosis_result["현황"].append(f"{folder} has write/modify/full control permission for Everyone")

    if has_permission_issue:
        diagnosis_result["진단결과"] = "취약"
        diagnosis_result["현황"].append("정책 위반: Excessive permissions found.")
    else:
        diagnosis_result["진단결과"] = "양호"
        diagnosis_result["현황"].append("정책 준수: Appropriate permissions set.")
else:
    diagnosis_result["현황"].append("정책 준수: IIS 서비스가 비활성화된 상태.")
    diagnosis_result["진단결과"] = "양호"

# Save the JSON results to a file
json_file_path = result_dir / 'W-24.json'
with open(json_file_path, 'w') as file:
    json.dump(diagnosis_result, file, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
