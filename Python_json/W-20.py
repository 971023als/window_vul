import os
import json
import subprocess
from pathlib import Path
import shutil

# JSON 객체 초기화
diagnosis_result = {
    "분류": "서비스관리",
    "코드": "W-20",
    "위험도": "상",
    "진단항목": "하드디스크 기본 공유 제거",
    "진단결과": "양호",  # 기본 값을 "양호"로 가정
    "현황": [],
    "대응방안": "하드디스크 기본 공유 제거"
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

# Default share analysis (simulated analysis, actual implementation may vary)
try:
    shares_output = subprocess.check_output('net share', text=True)
    default_shares = ["ADMIN$", "C$", "IPC$"]
    unauthorized_shares = [share for share in default_shares if share in shares_output]

    # Update the JSON object based on the AutoShareServer setting analysis
    if unauthorized_shares:
        diagnosis_result["현황"].append("문제 발견: 기본 공유가 생성되지 않는 문제를 해결")
        diagnosis_result["진단결과"] = "취약"
    else:
        diagnosis_result["현황"].append("문제 없음: 기본 공유가 생성되지 않아 보안 강화")
        diagnosis_result["진단결과"] = "양호"

except subprocess.CalledProcessError as e:
    diagnosis_result["현황"].append("문제 발견: AutoShareServer 설정 검사 실패")
    diagnosis_result["진단결과"] = "취약"

# Save the JSON results to a file
json_file_path = result_dir / 'W-20.json'
with open(json_file_path, 'w') as file:
    json.dump(diagnosis_result, file, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
