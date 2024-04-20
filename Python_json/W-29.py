import os
import json
import subprocess
from pathlib import Path
import shutil

# JSON 객체 초기화
diagnosis_result = {
    "분류": "계정 관리",
    "코드": "W-29",
    "위험도": "높음",
    "진단항목": "비밀번호 저장을 위한 복호화 가능한 암호화 사용",
    "진단결과": "양호",  # 기본 상태를 '양호'로 가정
    "현황": [],
    "대응방안": "비밀번호 저장을 위한 복호화 가능한 암호화 사용을 피하세요"
}

# 관리자 권한 확인 및 요청
if not os.getuid() == 0:
    print("관리자 권한이 필요합니다...")
    subprocess.call(['sudo', 'python3'] + sys.argv)
    sys.exit()

# 환경 설정 및 디렉터리 구성
computer_name = os.environ['COMPUTERNAME']
raw_dir = Path(f"C:\\Window_{computer_name}_raw")
result_dir = Path(f"C:\\Window_{computer_name}_result")

# 디렉터리 초기화
shutil.rmtree(raw_dir, ignore_errors=True)
shutil.rmtree(result_dir, ignore_errors=True)
raw_dir.mkdir(parents=True, exist_ok=True)
result_dir.mkdir(parents=True, exist_ok=True)

# 로컬 보안 정책 내보내기 및 시스템 정보 저장
subprocess.run(['secedit', '/export', '/cfg', str(raw_dir / "Local_Security_Policy.txt")])
(raw_dir / 'compare.txt').touch()
with open(raw_dir / 'systeminfo.txt', 'w') as f:
    subprocess.run(['systeminfo'], stdout=f)

# IIS 설정 분석
application_host_config_path = Path(os.environ['WINDIR']) / 'System32' / 'Inetsrv' / 'Config' / 'applicationHost.Config'
content = application_host_config_path.read_text() if application_host_config_path.exists() else ""
with open(raw_dir / 'iis_setting.txt', 'w') as file:
    file.write(content)
with open(raw_dir / 'iis_path1.txt', 'w') as file:
    file.write(content)

# 분석을 위한 경로 추출
line_contents = content.split('*')
for i in range(5):
    with open(raw_dir / f'path{i+1}.txt', 'w') as f:
        f.write(line_contents[i] if i < len(line_contents) else "")

# JSON 결과를 파일에 저장
json_file_path = result_dir / 'W-29.json'
with open(json_file_path, 'w') as file:
    json.dump(diagnosis_result, file, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
