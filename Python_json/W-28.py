import os
import json
import subprocess
from pathlib import Path
import shutil
import win32serviceutil

# JSON 객체 초기화
diagnosis_result = {
    "분류": "계정 관리",
    "코드": "W-28",
    "위험도": "높음",
    "진단항목": "비밀번호 저장에 복호화 가능한 암호화 사용하지 않기",
    "진단결과": "양호",  # 기본 상태를 '양호'로 가정
    "현황": [],
    "대응방안": "비밀번호 저장에 복호화 가능한 암호화 사용을 피하세요"
}

# 관리자 권한 확인 및 요청
if not os.getuid() == 0:
    print("관리자 권한이 필요합니다...")
    subprocess.call(['sudo', 'python3'] + sys.argv)
    sys.exit()

# 환경 및 디렉터리 설정
computer_name = os.environ['COMPUTERNAME']
raw_dir = Path(f"C:\\Window_{computer_name}_raw")
result_dir = Path(f"C:\\Window_{computer_name}_result")

# 디렉터리 초기화
shutil.rmtree(raw_dir, ignore_errors=True)
shutil.rmtree(result_dir, ignore_errors=True)
raw_dir.mkdir(parents=True, exist_ok=True)
result_dir.mkdir(parents=True, exist_ok=True)

# 보안 정책 내보내기 및 시스템 정보 수집
subprocess.run(['secedit', '/export', '/cfg', str(raw_dir / "Local_Security_Policy.txt")])
with open(raw_dir / 'install_path.txt', 'w') as f:
    f.write(str(raw_dir))
with open(raw_dir / 'systeminfo.txt', 'w') as f:
    subprocess.run(['systeminfo'], stdout=f)

# IIS 설정 분석
application_host_config_path = Path(os.environ['WINDIR']) / 'System32' / 'Inetsrv' / 'Config' / 'applicationHost.Config'
if application_host_config_path.exists():
    content = application_host_config_path.read_text()
    with open(raw_dir / 'iis_setting.txt', 'w') as file:
        file.write(content)
    with open(raw_dir / 'iis_path1.txt', 'w') as file:
        file.write(content)
else:
    with open(raw_dir / 'iis_path1.txt', 'w') as file:
        file.write(f"{application_host_config_path} 경로를 찾을 수 없습니다.")

# IIS 중요 경로에서 단축 파일 검사
service_status = win32serviceutil.QueryServiceStatus('W3SVC')
if service_status[1] == win32serviceutil.SERVICE_RUNNING:
    shortcut_found = False
    for i in range(1, 6):
        path = raw_dir / f"path{i}.txt"
        if path.exists():
            for file in path.glob('*.lnk'):
                shortcut_found = True
                diagnosis_result["현황"].append(f"{path} 경로에 단축 파일 (*.lnk)이 있습니다, 보안 위험이 있습니다.")

    if shortcut_found:
        diagnosis_result["진단결과"] = "취약"
    else:
        diagnosis_result["진단결과"] = "안전"
        diagnosis_result["현황"].append("IIS 중요 경로에 비인가 단축 파일이 없습니다, 보안 기준을 준수하고 있습니다.")
else:
    diagnosis_result["현황"].append("World Wide Web Publishing Service가 실행되지 않고 있습니다, 단축 파일 검사가 필요 없습니다.")

# JSON 결과를 파일에 저장
json_file_path = result_dir / 'W-28.json'
with open(json_file_path, 'w') as file:
    json.dump(diagnosis_result, file, ensure_ascii=False, indent=4)

print("스크립트 실행 완료")
