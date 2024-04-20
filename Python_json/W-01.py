import os
import json
import shutil
import subprocess
from pathlib import Path

# 진단 결과 JSON 객체
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-01",
    "위험도": "상",
    "진단항목": "Administrator 계정 이름 바꾸기",
    "진단결과": "양호",  # 기본 값을 "양호"로 가정
    "현황": [],
    "대응방안": "Administrator 계정 이름 변경"
}

# 관리자 권한 확인 및 스크립트 재실행 (파이썬에서는 직접적인 권한 상승 방법 제공하지 않음)
if not os.getuid() == 0:
    print("관리자 권한이 필요합니다...")
    subprocess.call(['sudo', 'python3'] + sys.argv)
    sys.exit()

# 기본 설정
computer_name = os.environ['COMPUTERNAME']
raw_path = Path(f"C:\\Window_{computer_name}_raw")
result_path = Path(f"C:\\Window_{computer_name}_result")

# 이전 파일 및 폴더 삭제
shutil.rmtree(raw_path, ignore_errors=True)
shutil.rmtree(result_path, ignore_errors=True)

# 새 폴더 생성
raw_path.mkdir(parents=True, exist_ok=True)
result_path.mkdir(parents=True, exist_ok=True)

# 로컬 보안 정책 내보내기
subprocess.run(['secedit', '/EXPORT', '/CFG', str(raw_path / "Local_Security_Policy.txt")])

# 시스템 정보 수집
with open(raw_path / 'systeminfo.txt', 'w') as f:
    subprocess.run(['systeminfo'], stdout=f)

# IIS 설정 수집
application_host_config = Path(os.environ['WINDIR']) / 'System32' / 'Inetsrv' / 'Config' / 'applicationHost.Config'
shutil.copy(application_host_config, raw_path / 'iis_setting.txt')

# 관리자 계정 이름 변경 여부 확인
local_security_policy = raw_path / 'Local_Security_Policy.txt'
try:
    with open(local_security_policy, 'r') as file:
        if "NewAdministratorName" not in file.read():
            diagnosis_result["진단결과"] = "취약"
            diagnosis_result["현황"].append("관리자 계정의 기본 이름이 변경되지 않았습니다.")
        else:
            diagnosis_result["현황"].append("관리자 계정의 기본 이름이 변경되었습니다.")
except FileNotFoundError:
    print("보안 정책 파일을 찾을 수 없습니다.")

# 진단 결과 JSON 파일로 저장
with open(result_path / 'W-01.json', 'w') as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

# 결과 보고서를 생성할 추가 코드를 여기에 포함시킬 수 있습니다.
print("스크립트 실행 완료")
