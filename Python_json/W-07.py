import os
import json
import subprocess
from pathlib import Path
import shutil

# JSON 객체 초기화
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-07",
    "위험도": "상",
    "진단항목": "Everyone 사용 권한을 익명 사용자에게 적용",
    "진단결과": "양호",  # 기본 값을 "양호"로 가정
    "현황": [],
    "대응방안": "Everyone 사용 권한을 익명 사용자에게 적용하지 않도록 설정"
}

# 관리자 권한 확인 및 요청 (파이썬에서는 직접적인 권한 상승을 수행할 수 없으므로 관리자 권한으로 실행되어야 함)
if not os.getuid() == 0:
    print("관리자 권한을 요청 중입니다...")
    subprocess.call(['sudo', 'python3'] + sys.argv)
    sys.exit()

# 초기 설정
computer_name = os.environ['COMPUTERNAME']
raw_dir = Path(f"C:\\Window_{computer_name}_raw")
result_dir = Path(f"C:\\Window_{computer_name}_result")

# 기존 폴더 및 파일 제거 및 새 폴더 생성
shutil.rmtree(raw_dir, ignore_errors=True)
shutil.rmtree(result_dir, ignore_errors=True)
raw_dir.mkdir(parents=True, exist_ok=True)
result_dir.mkdir(parents=True, exist_ok=True)

# 보안 정책 파일 생성
subprocess.run(['secedit', '/export', '/cfg', str(raw_dir / "Local_Security_Policy.txt")])

# 시스템 정보 및 IIS 구성 수집
with open(raw_dir / 'systeminfo.txt', 'w') as f:
    subprocess.run(['systeminfo'], stdout=f)

application_host_config = Path(os.environ['WINDIR']) / 'System32' / 'Inetsrv' / 'Config' / 'applicationHost.Config'
metabase_config = Path(os.environ['WINDIR']) / 'System32' / 'Inetsrv' / 'MetaBase.xml'
shutil.copy(application_host_config, raw_dir / 'iis_setting.txt')
shutil.copy(metabase_config, raw_dir / 'iis_setting.txt', append=True)

# "EveryoneIncludesAnonymous" 정책 검사
security_policy_file = raw_dir / "Local_Security_Policy.txt"
if security_policy_file.exists():
    with open(security_policy_file, 'r') as file:
        local_security_policy = file.read()
        if "EveryoneIncludesAnonymous = 0" in local_security_policy:
            diagnosis_result["현황"].append("'모든 사용자가 익명 사용자를 포함' 정책이 '사용 안 함'으로 올바르게 설정되어 더 높은 보안을 보장합니다.")
        else:
            diagnosis_result["진단결과"] = "취약"
            diagnosis_result["현황"].append("'모든 사용자가 익명 사용자를 포함' 정책이 '사용 안 함'으로 설정되지 않아 잠재적 보안 위험을 초래합니다.")

# JSON 결과를 파일로 저장
json_file_path = result_dir / 'W-07.json'
with open(json_file_path, 'w') as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
