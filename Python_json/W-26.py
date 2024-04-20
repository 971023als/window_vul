import os
import json
import subprocess
from pathlib import Path
import shutil

# JSON 객체 초기화
diagnosis_result = {
    "분류": "계정 관리",
    "코드": "W-26",
    "위험도": "높음",
    "진단항목": "비밀번호 저장을 위한 복호화 가능한 암호화 사용",
    "진단결과": "양호",  # 기본 상태를 '양호'로 가정
    "현황": [],
    "대응방안": "비밀번호 저장을 위한 복호화 가능한 암호화 사용"
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
with open(raw_dir / 'install_path.txt', 'w') as f:
    f.write(str(raw_dir))
with open(raw_dir / 'systeminfo.txt', 'w') as f:
    subprocess.run(['systeminfo'], stdout=f)

# IIS 설정 분석
application_host_config_path = Path(os.environ['WINDIR']) / 'System32' / 'Inetsrv' / 'Config' / 'applicationHost.Config'
with open(application_host_config_path) as file:
    content = file.read()
with open(raw_dir / 'iis_setting.txt', 'w') as file:
    file.write(content)

# 취약한 디렉토리 검사
service_status = subprocess.run(['sc', 'query', 'W3SVC'], text=True, capture_output=True)
is_running = "RUNNING" in service_status.stdout
vulnerable_dirs = [
    Path("c:/program files/common files/system/msadc/sample"),
    Path("c:/winnt/help/iishelp"),
    Path("c:/inetpub/iissamples"),
    Path(f"{os.environ['SYSTEMROOT']}/System32/Inetsrv/IISADMPWD")
]
vulnerable_found = any(dir.exists() for dir in vulnerable_dirs)

if is_running and vulnerable_found:
    diagnosis_result["진단결과"] = "취약"
    diagnosis_result["현황"].append("정책 위반 감지: 취약한 디렉토리가 발견되었습니다.")
else:
    diagnosis_result["진단결과"] = "안전"
    diagnosis_result["현황"].append("규정 준수: 취약한 디렉토리가 발견되지 않았거나 IIS 서비스가 실행되지 않고 있습니다.")

# JSON 결과를 파일에 저장
json_file_path = result_dir / 'W-26.json'
with open(json_file_path, 'w') as file:
    json.dump(diagnosis_result, file, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
