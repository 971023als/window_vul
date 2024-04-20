import os
import json
import subprocess
from pathlib import Path
import shutil
import re

# JSON 객체 초기화
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-13",
    "위험도": "상",
    "진단항목": "마지막 사용자 이름 표시 안함",
    "진단결과": "양호",  # 기본 값을 "양호"로 가정
    "현황": [],
    "대응방안": "마지막 사용자 이름 표시 안함 설정"
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
iis_data = subprocess.check_output(['findstr', 'physicalPath bindingInformation', str(raw_dir / 'iis_setting.txt')])
with open(raw_dir / 'iis_path1.txt', 'wb') as f:
    f.write(iis_data)

# 보안 정책 분석 - DontDisplayLastUserName
with open(raw_dir / "Local_Security_Policy.txt") as file:
    local_security_policy = file.read()
    policy_analysis = re.search(r"DontDisplayLastUserName\s*=\s*1", local_security_policy)

# Update the JSON object based on the "DontDisplayLastUserName" policy analysis
if policy_analysis:
    diagnosis_result["현황"].append("준수: 마지막으로 로그온한 사용자 이름을 표시하지 않는 정책이 활성화되어 있습니다.")
else:
    diagnosis_result["진단결과"] = "취약"
    diagnosis_result["현황"].append("미준수: 마지막으로 로그온한 사용자 이름을 표시하지 않는 정책이 비활성화되어 있습니다.")

# Save the JSON results to a file named "W-13.json"
json_file_path = result_dir / 'W-13.json'
with open(json_file_path, 'w') as file:
    json.dump(diagnosis_result, file, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
