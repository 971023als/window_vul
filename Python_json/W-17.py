import os
import json
import subprocess
from pathlib import Path
import shutil
import re

# JSON 객체 초기화
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-17",
    "위험도": "상",
    "진단항목": "콘솔 로그온 시 로컬 계정에서 빈 암호 사용 제한",
    "진단결과": "양호",  # 기본 값을 "양호"로 가정
    "현황": [],
    "대응방안": "콘솔 로그온 시 로컬 계정에서 빈 암호 사용 제한"
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

# "LimitBlankPasswordUse" 보안 정책 감사
with open(raw_dir / "Local_Security_Policy.txt") as file:
    local_security_policy = file.read()
    if "LimitBlankPasswordUse = 1" in local_security_policy:
        diagnosis_result["현황"].append("준수 확인됨: 'LimitBlankPasswordUse' 정책이 올바르게 적용됨.")
        diagnosis_result["진단결과"] = "양호"
    else:
        diagnosis_result["진단결과"] = "취약"
        diagnosis_result["현황"].append("준수하지 않음 감지됨: 'LimitBlankPasswordUse' 정책이 올바르게 적용되지 않음.")

# Save the JSON results to a file
json_file_path = result_dir / 'W-17.json'
with open(json_file_path, 'w') as file:
    json.dump(diagnosis_result, file, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
