import os
import json
import subprocess
import ctypes
from pathlib import Path

# ---------------------------------
# 관리자 권한 체크
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
    "코드": "W-21",
    "위험도": "상",
    "진단항목": "암호화되지 않는 FTP 서비스 비활성화",
    "진단결과": "양호",
    "현황": [],
    "대응방안": "FTP 서비스 비활성화 또는 SFTP 사용"
}

weak_found = False

# ---------------------------------
# 1️⃣ Windows 서비스 확인
# ---------------------------------
services_to_check = [
    "FTPSVC",                 # IIS FTP
    "MSFTPSVC",               # 구버전
    "Microsoft FTP Service",
    "FileZilla Server"
]

for svc in services_to_check:
    try:
        result = subprocess.run(
            ["sc", "query", svc],
            capture_output=True,
            text=True
        )

        if result.returncode == 0:
            with open(raw_path / "W-21_service_raw.txt", "a", encoding="utf-8") as f:
                f.write(result.stdout + "\n")

            if "RUNNING" in result.stdout:
                weak_found = True
                diagnosis_result["현황"].append(f"{svc} 서비스 실행 중")
            else:
                diagnosis_result["현황"].append(f"{svc} 서비스 존재 (중지 상태)")

    except Exception:
        pass

# ---------------------------------
# 2️⃣ 포트 21 LISTEN 확인
# ---------------------------------
netstat = subprocess.run(
    ["netstat", "-ano"],
    capture_output=True,
    text=True
).stdout

with open(raw_path / "W-21_port_raw.txt", "w", encoding="utf-8") as f:
    f.write(netstat)

for line in netstat.splitlines():
    if ":21" in line and "LISTEN" in line.upper():
        weak_found = True
        diagnosis_result["현황"].append(f"FTP 포트 21 LISTEN 발견: {line.strip()}")

# ---------------------------------
# 최종 판정
# ---------------------------------
if weak_found:
    diagnosis_result["진단결과"] = "취약"
else:
    diagnosis_result["현황"].append("FTP 서비스 미사용 또는 비활성화 상태")
    diagnosis_result["진단결과"] = "양호"

# ---------------------------------
# 결과 저장
# ---------------------------------
with open(result_path / "W-21.json", "w", encoding="utf-8") as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("W-21 점검 완료")
print(f"결과 위치: {result_path}\\W-21.json")
