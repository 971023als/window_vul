import os
import json
import subprocess
from pathlib import Path
import shutil

# JSON 객체 초기화
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-04",
    "위험도": "상",
    "진단항목": "계정 잠금 임계값 설정",
    "진단결과": "양호",  # 기본 값을 "양호"로 가정
    "현황": [],
    "대응방안": "계정 잠금 임계값 설정"
}

# 관리자 권한 확인 및 요청 (파이썬에서는 직접적인 권한 상승을 수행할 수 없으므로 관리자 권한으로 실행되어야 함)
if not os.getuid() == 0:
    print("관리자 권한이 필요합니다...")
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

# 보안 정책, 시스템 정보 등 수집
subprocess.run(['secedit', '/export', '/cfg', str(raw_dir / "Local_Security_Policy.txt")])
security_config = raw_dir / "Local_Security_Policy.txt"

# 시스템 정보 수집
with open(raw_dir / 'systeminfo.txt', 'w') as f:
    subprocess.run(['systeminfo'], stdout=f)

# IIS 설정 수집
application_host_config = Path(os.environ['WINDIR']) / 'System32' / 'Inetsrv' / 'Config' / 'applicationHost.Config'
shutil.copy(application_host_config, raw_dir / 'iis_setting.txt')

# 계정 잠금 임계값 검사
if security_config.exists():
    with open(security_config, 'r') as file:
        lines = file.readlines()
        lockout_threshold = [line.split('=')[1].strip() for line in lines if "LockoutBadCount" in line][0]

        # 계정 잠금 임계값 검사 후 JSON 객체 업데이트
        if int(lockout_threshold) > 5:
            diagnosis_result["진단결과"] = "취약"
            diagnosis_result["현황"].append("계정 잠금 임계값이 5회 시도보다 많게 설정되어 있습니다.")
        elif int(lockout_threshold) == 0:
            diagnosis_result["진단결과"] = "취약"
            diagnosis_result["현황"].append("계정 잠금 임계값이 설정되지 않았습니다(없음).")
        else:
            diagnosis_result["현황"].append("계정 잠금 임계값이 준수 범위 내에 설정되었습니다.")

# JSON 결과를 파일로 저장
json_file_path = result_dir / 'W-04.json'
with open(json_file_path, 'w') as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
