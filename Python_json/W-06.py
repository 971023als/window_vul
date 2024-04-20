import os
import json
import subprocess
from pathlib import Path
import shutil

# JSON 객체 초기화
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-06",
    "위험도": "상",
    "진단항목": "관리자 그룹에 최소한의 사용자 포함",
    "진단결과": "양호",  # 기본 값을 "양호"로 가정
    "현황": [],
    "대응방안": "관리자 그룹에 최소한의 사용자 포함"
}

# 관리자 권한 확인 및 요청 (파이썬에서는 직접적인 권한 상승을 수행할 수 없으므로 관리자 권한으로 실행되어야 함)
if not os.getuid() == 0:
    print("관리자 권한을 요청하는 중...")
    subprocess.call(['sudo', 'python3'] + sys.argv)
    sys.exit()

# 초기 환경 설정
computer_name = os.environ['COMPUTERNAME']
raw_dir = Path(f"C:\\Window_{computer_name}_raw")
result_dir = Path(f"C:\\Window_{computer_name}_result")

# 기존 폴더 및 파일 제거 및 새 폴더 생성
shutil.rmtree(raw_dir, ignore_errors=True)
shutil.rmtree(result_dir, ignore_errors=True)
raw_dir.mkdir(parents=True, exist_ok=True)
result_dir.mkdir(parents=True, exist_ok=True)

# 시스템 정보 수집
with open(raw_dir / 'systeminfo.txt', 'w') as f:
    subprocess.run(['systeminfo'], stdout=f)

# IIS 구성 수집
application_host_config = Path(os.environ['WINDIR']) / 'System32' / 'Inetsrv' / 'Config' / 'applicationHost.Config'
metabase_config = Path(os.environ['WINDIR']) / 'System32' / 'Inetsrv' / 'MetaBase.xml'
shutil.copy(application_host_config, raw_dir / 'iis_setting.txt')
shutil.copy(metabase_config, raw_dir / 'iis_setting.txt', append=True)

# 관리자 그룹 멤버십 검사
administrators_output = subprocess.check_output('net localgroup Administrators', shell=True).decode()
non_compliant_accounts = [line for line in administrators_output.split('\n') if "test" in line or "Guest" in line]

# 관리자 그룹 멤버십 검사 후 JSON 객체 업데이트
if non_compliant_accounts:
    diagnosis_result["진단결과"] = "취약"
    diagnosis_result["현황"].append("관리자 그룹에 임시 또는 게스트 계정('test', 'Guest')이 포함되어 있습니다.")
else:
    diagnosis_result["현황"].append("관리자 그룹에 임시 또는 게스트 계정이 포함되지 않아 보안 정책을 준수합니다.")

# JSON 결과를 파일로 저장
json_file_path = result_dir / 'W-06.json'
with open(json_file_path, 'w') as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
