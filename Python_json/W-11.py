import os
import json
import subprocess
from pathlib import Path
import shutil
import re

# JSON 객체 초기화
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-11",
    "위험도": "상",
    "진단항목": "패스워드 최대 사용 기간",
    "진단결과": "양호",  # 기본 값을 "양호"로 가정
    "현황": [],
    "대응방안": "패스워드 최대 사용 기간 설정"
}

# 관리자 권한 확인 및 요청 (파이썬에서는 직접적인 권한 상승을 수행할 수 없으므로 관리자 권한으로 실행되어야 함)
if not os.getuid() == 0:
    print("관리자 권한이 필요합니다...")
    subprocess.call(['sudo', 'python3'] + sys.argv)
    sys.exit()

# 변수 설정
computer_name = os.environ['COMPUTERNAME']
raw_dir = Path(f"C:\\Window_{computer_name}_raw")
result_dir = Path(f"C:\\Window_{computer_name}_result")

# 디렉터리 초기화
shutil.rmtree(raw_dir, ignore_errors=True)
shutil.rmtree(result_dir, ignore_errors=True)
raw_dir.mkdir(parents=True, exist_ok=True)
result_dir.mkdir(parents=True, exist_ok=True)

# 기본 정보 수집
subprocess.run(['secedit', '/export', '/cfg', str(raw_dir / "Local_Security_Policy.txt")])
(raw_dir / 'compare.txt').touch()
with open(raw_dir / 'install_path.txt', 'w') as f:
    f.write(str(raw_dir))

with open(raw_dir / 'systeminfo.txt', 'w') as f:
    subprocess.run(['systeminfo'], stdout=f)

# IIS 설정 파일 읽기
application_host_config = Path(os.environ['WINDIR']) / 'System32' / 'Inetsrv' / 'Config' / 'applicationHost.Config'
with open(application_host_config) as file:
    content = file.read()
with open(raw_dir / 'iis_setting.txt', 'w') as file:
    file.write(content)

# 최대암호사용기간 분석
with open(raw_dir / "Local_Security_Policy.txt") as file:
    local_security_policy = file.read()
    match = re.search(r"MaximumPasswordAge\s*=\s*(\d+)", local_security_policy)
    if match:
        maximum_password_age = int(match.group(1))
        if maximum_password_age <= 90:
            diagnosis_result["현황"].append(f"최대 암호 사용 기간 정책이 준수됩니다. {maximum_password_age}일로 설정됨.")
        else:
            diagnosis_result["진단결과"] = "취약"
            diagnosis_result["현황"].append(f"최대 암호 사용 기간 정책이 준수되지 않습니다. {maximum_password_age}일로 설정됨.")
    else:
        diagnosis_result["현황"].append("최대암호사용기간 정책 정보를 찾을 수 없습니다.")

# JSON 결과를 파일로 저장
json_file_path = result_dir / 'W-11.json'
with open(json_file_path, 'w') as file:
    json.dump(diagnosis_result, file, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
