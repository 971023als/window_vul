import os
import json
import subprocess
from pathlib import Path
import shutil
import re

# JSON 객체 초기화
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-12",
    "위험도": "상",
    "진단항목": "패스워드최소사용기간",
    "진단결과": "양호",  # 기본 값을 "양호"로 가정
    "현황": [],
    "대응방안": "패스워드최소사용기간 설정"
}

# 관리자 권한 확인 및 요청 (파이썬에서는 직접적인 권한 상승을 수행할 수 없으므로 관리자 권한으로 실행되어야 함)
if not os.getuid() == 0:
    print("관리자 권한이 필요합니다...")
    subprocess.call(['sudo', 'python3'] + sys.argv)
    sys.exit()

# 디렉터리 및 파일 초기화
computer_name = os.environ['COMPUTERNAME']
raw_dir = Path(f"C:\\Window_{computer_name}_raw")
result_dir = Path(f"C:\\Window_{computer_name}_result")

shutil.rmtree(raw_dir, ignore_errors=True)
shutil.rmtree(result_dir, ignore_errors=True)
raw_dir.mkdir(parents=True, exist_ok=True)
result_dir.mkdir(parents=True, exist_ok=True)

# 보안 정책 파일 생성 및 시스템 정보 수집
subprocess.run(['secedit', '/export', '/cfg', str(raw_dir / "Local_Security_Policy.txt")])
(raw_dir / 'compare.txt').touch()
with open(raw_dir / 'install_path.txt', 'w') as f:
    f.write(str(raw_dir))
with open(raw_dir / 'systeminfo.txt', 'w') as f:
    subprocess.run(['systeminfo'], stdout=f)

# IIS 설정 파일 복사 및 분석
application_host_config = Path(os.environ['WINDIR']) / 'System32' / 'Inetsrv' / 'Config' / 'applicationHost.Config'
shutil.copy(application_host_config, raw_dir / 'iis_setting.txt')
iis_data = subprocess.check_output(['findstr', 'physicalPath bindingInformation', str(raw_dir / 'iis_setting.txt')])
with open(raw_dir / 'iis_path1.txt', 'wb') as f:
    f.write(iis_data)

# 최소 암호 사용 기간 분석
with open(raw_dir / "Local_Security_Policy.txt") as file:
    local_security_policy = file.read()
    match = re.search(r"MinimumPasswordAge\s*=\s*(\d+)", local_security_policy)
    if match:
        minimum_password_age = int(match.group(1))
        if minimum_password_age > 0:
            diagnosis_result["현황"].append(f"최소 암호 사용 기간은 설정됨: {minimum_password_age}일.")
        else:
            diagnosis_result["진단결과"] = "취약"
            diagnosis_result["현황"].append("최소 암호 사용 기간이 설정되지 않음.")
    else:
        diagnosis_result["현황"].append("최소암호사용기간 정책 정보를 찾을 수 없습니다.")

# JSON 결과를 파일로 저장
json_file_path = result_dir / 'W-12.json'
with open(json_file_path, 'w') as file:
    json.dump(diagnosis_result, file, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
