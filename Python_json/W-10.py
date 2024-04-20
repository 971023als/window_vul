import os
import json
import subprocess
from pathlib import Path
import shutil

# JSON 객체 초기화
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-10",
    "위험도": "상",
    "진단항목": "패스워드 최소 암호 길이",
    "진단결과": "양호",  # 기본 값을 "양호"로 가정
    "현황": [],
    "대응방안": "패스워드 최소 암호 길이 설정"
}

# 관리자 권한 확인 및 요청 (파이썬에서는 직접적인 권한 상승을 수행할 수 없으므로 관리자 권한으로 실행되어야 함)
if not os.getuid() == 0:
    print("관리자 권한이 필요합니다...")
    subprocess.call(['sudo', 'python3'] + sys.argv)
    sys.exit()

# 초기 설정
computer_name = os.environ['COMPUTERNAME']
base_dir = Path(f"C:\\Window_{computer_name}")
raw_dir = base_dir / "raw"
result_dir = base_dir / "result"

# 기존 폴더 및 파일 제거 및 새 폴더 생성
shutil.rmtree(raw_dir, ignore_errors=True)
shutil.rmtree(result_dir, ignore_errors=True)
raw_dir.mkdir(parents=True, exist_ok=True)
result_dir.mkdir(parents=True, exist_ok=True)

# 보안 정책 파일 생성 및 시스템 정보 수집
subprocess.run(['secedit', '/export', '/cfg', str(raw_dir / "Local_Security_Policy.txt")])
with open(raw_dir / 'systeminfo.txt', 'w') as f:
    subprocess.run(['systeminfo'], stdout=f)

# "user.txt" 파일 생성 후 사용자 정보 읽기
(user_txt := raw_dir / "user.txt").write_text("User1\nUser2")

# "user.txt" 파일에서 사용자 정보 읽어오기
user_info = {}
with open(user_txt, 'r') as file:
    for line in file:
        user = line.strip()
        command_output = subprocess.check_output(f'net user {user}', shell=True).decode()
        if "계정 활성 상태\t:\t예" in command_output:
            user_info[user] = command_output

# 로컬 보안 정책 정보 읽어오기 및 분석
with open(raw_dir / "Local_Security_Policy.txt", 'r') as file:
    policy_info = file.read()
    # 최소암호사용기간 분석 후 JSON 객체 업데이트
    if (match := re.search(r"최소암호길이\s*:\s*(\d+)", policy_info)):
        min_length = int(match.group(1))
        if min_length >= 8:
            diagnosis_result["현황"].append(f"최소암호길이가 {min_length}글자로 설정되어 정책을 준수합니다.")
        else:
            diagnosis_result["진단결과"] = "취약"
            diagnosis_result["현황"].append(f"최소암호길이가 {min_length}글자 미만으로 설정되어 정책을 준수하지 않습니다.")

# JSON 결과를 파일로 저장
json_file_path = result_dir / 'W-10.json'
with open(json_file_path, 'w') as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
