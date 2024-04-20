import os
import json
import subprocess
from pathlib import Path
import shutil

# JSON 객체 초기화
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-03",
    "위험도": "상",
    "진단항목": "불필요한 계정 제거",
    "진단결과": "양호",  # 기본 값을 "양호"로 가정
    "현황": [],
    "대응방안": "불필요한 계정 제거"
}

# 관리자 권한 확인 및 요청 (파이썬에서는 직접적인 권한 상승을 수행할 수 없으므로 관리자 권한으로 실행되어야 함)
if not os.getuid() == 0:
    print("관리자 권한이 필요합니다...")
    subprocess.call(['sudo', 'python3'] + sys.argv)
    sys.exit()

# 콘솔 환경 설정
print("------------------------------------------설정---------------------------------------")

computer_name = os.environ['COMPUTERNAME']
raw_path = Path(f"C:\\Window_{computer_name}_raw")
result_path = Path(f"C:\\Window_{computer_name}_result")

# 기존 폴더 및 파일 제거 및 새 폴더 생성
shutil.rmtree(raw_path, ignore_errors=True)
shutil.rmtree(result_path, ignore_errors=True)
raw_path.mkdir(parents=True, exist_ok=True)
result_path.mkdir(parents=True, exist_ok=True)

# 보안 정책, 시스템 정보 등 수집
subprocess.run(['secedit', '/export', '/cfg', str(raw_path / "Local_Security_Policy.txt")])
(raw_path / "compare.txt").touch()
with open(raw_path / 'install_path.txt', 'w') as f:
    f.write(str(Path.cwd()))

with open(raw_path / 'systeminfo.txt', 'w') as f:
    subprocess.run(['systeminfo'], stdout=f)

# IIS 설정 정보 수집
application_host_config = Path(os.environ['WINDIR']) / 'System32' / 'inetsrv' / 'config' / 'applicationHost.Config'
shutil.copy(application_host_config, raw_path / 'iis_setting.txt')

# 사용자 계정 정보 수집 및 분석
users_output = subprocess.check_output('net user', shell=True).decode()
users = [line.strip() for line in users_output.split('\n') if line.strip() and line.strip().isalpha()]

for user in users:
    user_info = subprocess.check_output(f'net user {user}', shell=True).decode()
    is_active = "Account active               Yes" in user_info
    if is_active:
        diagnosis_result["진단결과"] = "취약"
        diagnosis_result["현황"].append(f"활성화된 계정: {user}")
        with open(raw_path / f'user_{user}.txt', 'w') as f:
            f.write(user_info)

# JSON 결과를 파일로 저장
json_file_path = result_path / 'W-03.json'
with open(json_file_path, 'w') as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
