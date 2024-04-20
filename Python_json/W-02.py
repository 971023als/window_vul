import os
import json
import subprocess
from pathlib import Path

# 게스트 계정 상태 확인 후 JSON 객체 업데이트
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-02",
    "위험도": "상",
    "진단항목": "Guest 계정 상태",
    "진단결과": "양호",  # 기본 값을 "양호"로 가정
    "현황": [],
    "대응방안": "Guest 계정 상태 변경"
}

# 관리자 권한 확인 및 요청 (파이썬에서는 직접적인 권한 상승을 수행할 수 없으므로 관리자 권한으로 실행되어야 함)
if not os.getuid() == 0:
    print("관리자 권한이 필요합니다...")
    subprocess.call(['sudo', 'python3'] + sys.argv)
    sys.exit()

# 기본 디렉터리 설정
computer_name = os.environ['COMPUTERNAME']
raw_dir = Path(f"C:\\Window_{computer_name}_raw")
result_dir = Path(f"C:\\Window_{computer_name}_result")

# 이전 파일 및 폴더 삭제
for directory in [raw_dir, result_dir]:
    if directory.exists():
        shutil.rmtree(directory)

# 새 폴더 생성
raw_dir.mkdir(parents=True, exist_ok=True)
result_dir.mkdir(parents=True, exist_ok=True)

# 로컬 보안 정책 내보내기 및 기본 파일 생성
subprocess.run(['secedit', '/export', '/cfg', str(raw_dir / "Local_Security_Policy.txt")])
(raw_dir / "compare.txt").touch()

# 시스템 정보 수집
with open(raw_dir / 'systeminfo.txt', 'w') as f:
    subprocess.run(['systeminfo'], stdout=f)

# IIS 설정 수집
application_host_config = Path(os.environ['WINDIR']) / 'System32' / 'Inetsrv' / 'Config' / 'applicationHost.Config'
shutil.copy(application_host_config, raw_dir / 'iis_setting.txt')

# 게스트 계정 정보 수집 및 분석
guest_account_info = subprocess.check_output(['net', 'user', 'guest']).decode()
is_active = "Account active               Yes" in guest_account_info

if is_active:
    diagnosis_result["진단결과"] = "취약"
    diagnosis_result["현황"].append("게스트 계정이 활성화 되어 있는 위험 상태로, 조치가 필요합니다.")
else:
    diagnosis_result["현황"].append("게스트 계정이 비활성화 상태로 유지되고 있으므로 안전합니다.")

# JSON 객체를 JSON 파일로 저장
with open(result_dir / 'W-02.json', 'w') as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
