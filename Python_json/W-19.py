import os
import json
import subprocess
from pathlib import Path
import shutil

# JSON 객체 초기화
diagnosis_result = {
    "분류": "서비스관리",
    "코드": "W-19",
    "위험도": "상",
    "진단항목": "공유 권한 및 사용자 그룹 설정",
    "진단결과": "양호",  # 기본 값을 "양호"로 가정
    "현황": [],
    "대응방안": "공유 권한 및 사용자 그룹 설정"
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

# 공유 폴더 접근 권한 분석
try:
    share_info_output = subprocess.check_output('net share', text=True)
    shares = [line.split() for line in share_info_output.splitlines() if line and "$" not in line and "command" not in line and "-" not in line]
    permission_details = []

    for share in shares:
        if len(share) > 1:
            share_path = share[1]
            acl_output = subprocess.check_output(f'cacls {share_path}', text=True)
            permission_details.append(acl_output)

    # 결과를 파일로 저장
    with open(raw_dir / 'W-19.txt', 'w') as f:
        f.writelines('\n'.join(permission_details))

    # Update the JSON object based on the shared folder permissions analysis
    if "Everyone" in str(permission_details):
        diagnosis_result["현황"].append("문제 발견: 공유 폴더 설정을 점검하거나 필요한 폴더만 공유하며, 공유 설정에서 Everyone 그룹의 접근을 제한하세요.")
        diagnosis_result["진단결과"] = "취약"
    else:
        diagnosis_result["현황"].append("문제 없음: 공유 폴더 보안 설정이 적절하며, Everyone 그룹의 접근이 제한되어 있습니다.")
        diagnosis_result["진단결과"] = "양호"

except subprocess.CalledProcessError as e:
    print("Error accessing share information:", e)

# Save the JSON results to a file
json_file_path = result_dir / 'W-19.json'
with open(json_file_path, 'w') as file:
    json.dump(diagnosis_result, file, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
