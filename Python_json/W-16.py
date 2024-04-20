import os
import json
import subprocess
from pathlib import Path
import shutil

# JSON 객체 초기화
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-16",
    "위험도": "상",
    "진단항목": "최근 암호 기억",
    "진단결과": "양호",  # 기본 값을 "양호"로 가정
    "현황": [],
    "대응방안": "최근 암호 기억 설정"
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

# 비밀번호 정책 분석
with open(raw_dir / "Local_Security_Policy.txt") as file:
    local_security_policy = file.read()
    password_history_size = re.search(r"PasswordHistorySize\s*=\s*(\d+)", local_security_policy)
    if password_history_size:
        password_history_size = int(password_history_size.group(1))
        if password_history_size > 11:
            diagnosis_result["현황"].append(f"준수 확인됨: 비밀번호 이력 크기가 11개 이전 비밀번호를 초과하도록 설정됨.")
            diagnosis_result["진단결과"] = "양호"
        else:
            diagnosis_result["진단결과"] = "취약"
            diagnosis_result["현황"].append("준수하지 않음 감지됨: 비밀번호 이력 크기가 11개 이전 비밀번호를 초과하지 않음.")

# Save the JSON results to a file
json_file_path = result_dir / 'W-16.json'
with open(json_file_path, 'w') as file:
    json.dump(diagnosis_result, file, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
