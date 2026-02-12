import os
import json
import subprocess
import ctypes
from pathlib import Path

# ---------------------------------
# 관리자 권한 확인
# ---------------------------------
def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

if not is_admin():
    print("관리자 권한으로 실행 필요")
    exit(1)

# ---------------------------------
# 기본 경로 생성
# ---------------------------------
computer_name = os.environ.get("COMPUTERNAME", "UNKNOWN")

raw_path = Path(f"C:\\Windows_{computer_name}_raw")
result_path = Path(f"C:\\Windows_{computer_name}_result")

raw_path.mkdir(parents=True, exist_ok=True)
result_path.mkdir(parents=True, exist_ok=True)

# ---------------------------------
# 결과 JSON 구조
# ---------------------------------
diagnosis_result = {
    "분류": "서비스관리",
    "코드": "W-18",
    "위험도": "상",
    "진단항목": "불필요한 서비스 제거",
    "진단결과": "양호",
    "현황": [],
    "대응방안": "불필요 서비스 중지 및 시작유형 사용안함 설정"
}

# ---------------------------------
# 점검 대상 서비스 목록
# 환경 맞게 추가 가능
# ---------------------------------
weak_services = [
    "Telnet",
    "TlntSvr",
    "FTP",
    "SNMP",
    "SNMPTRAP",
    "RemoteRegistry",
    "Messenger",
    "Alerter",
    "Browser"
]

running_weak = []

# ---------------------------------
# 전체 서비스 상태 수집
# ---------------------------------
try:
    result = subprocess.run("sc query state= all", shell=True, capture_output=True, text=True)

    with open(raw_path / "W-18_service_list.txt", "w", encoding="utf-8") as f:
        f.write(result.stdout)

    output = result.stdout.lower()

    for svc in weak_services:
        if svc.lower() in output:
            # 개별 상태 확인
            check = subprocess.run(f'sc query "{svc}"', shell=True, capture_output=True, text=True).stdout.lower()
            if "running" in check:
                running_weak.append(svc)

except Exception as e:
    diagnosis_result["현황"].append(str(e))
    diagnosis_result["진단결과"] = "취약"

# ---------------------------------
# 결과 판정
# ---------------------------------
if running_weak:
    diagnosis_result["진단결과"] = "취약"
    diagnosis_result["현황"].append(f"불필요 서비스 실행중: {', '.join(running_weak)}")
else:
    diagnosis_result["현황"].append("불필요 서비스 실행 없음")

# ---------------------------------
# 결과 저장
# ---------------------------------
with open(result_path / "W-18.json", "w", encoding="utf-8") as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("W-18 점검 완료")
print(f"결과 위치: {result_path}\\W-18.json")
