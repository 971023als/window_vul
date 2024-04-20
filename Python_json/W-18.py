import os
import json
import subprocess
from pathlib import Path
import shutil

# JSON 객체 초기화
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-18",
    "위험도": "상",
    "진단항목": "원격터미널 접속 가능한 사용자 그룹 제한",
    "진단결과": "양호",  # 기본 값을 "양호"로 가정
    "현황": [],
    "대응방안": "원격터미널 접속 가능한 사용자 그룹 제한"
}

# 관리자 권한 확인 및 요청 (파이썬에서는 직접적인 권한 상승을 수행할 수 없으므로 관리자 권한으로 실행되어야 함)
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
(raw_dir / 'compare.txt').touch()
with open(raw_dir / 'install_path.txt', 'w') as f:
    f.write(str(raw_dir))
with open(raw_dir / 'systeminfo.txt', 'w') as f:
    subprocess.run(['systeminfo'], stdout=f)

# IIS 설정 분석
application_host_config = Path(os.environ['WINDIR']) / 'System32' / 'Inetsrv' / 'Config' / 'applicationHost.Config'
with open(application_host_config) as file:
    content = file.read()
with open(raw_dir / 'iis_setting.txt', 'w') as file:
    file.write(content)

# 사용자 그룹 분석
user_list = ["User1", "User2"]  # Example user list, adapt as necessary
user_remote_details = []

for user in user_list:
    try:
        user_info = subprocess.check_output(['net', 'user', user], text=True)
        if "Remote Desktop Users" in user_info:
            user_remote_details.append("----------------------------------------------------")
            user_remote_details.append(user_info)
            user_remote_details.append("----------------------------------------------------")
    except subprocess.CalledProcessError as e:
        continue  # Handle the case where the 'net user' command fails

# 결과를 파일로 저장
with open(raw_dir / 'user_Remote.txt', 'w') as file:
    file.write('\n'.join(user_remote_details))

# Update the JSON object based on the unauthorized users check
if user_remote_details:
    diagnosis_result["현황"].append("무단 사용자가 'Remote Desktop Users' 그룹에 발견되었습니다.")
    diagnosis_result["진단결과"] = "취약"
else:
    diagnosis_result["현황"].append("'Remote Desktop Users' 그룹에 무단 사용자가 없습니다. 준수 상태가 확인되었습니다.")
    diagnosis_result["진단결과"] = "양호"

# Save the JSON results to a file
json_file_path = result_dir / 'W-18.json'
with open(json_file_path, 'w') as file:
    json.dump(diagnosis_result, file, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
