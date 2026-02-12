import os
import json
import subprocess
import ctypes
import winreg
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
# 기본 경로
# ---------------------------------
computer_name = os.environ.get("COMPUTERNAME", "UNKNOWN")

raw_path = Path(f"C:\\Windows_{computer_name}_raw")
result_path = Path(f"C:\\Windows_{computer_name}_result")

raw_path.mkdir(parents=True, exist_ok=True)
result_path.mkdir(parents=True, exist_ok=True)

# ---------------------------------
# 결과 JSON
# ---------------------------------
diagnosis_result = {
    "분류": "서비스관리",
    "코드": "W-17",
    "위험도": "상",
    "진단항목": "하드디스크 기본 공유 제거",
    "진단결과": "양호",
    "현황": [],
    "대응방안": "기본 공유 제거 및 AutoShareServer 레지스트리 0 설정"
}

# ---------------------------------
# 1️⃣ 레지스트리 AutoShareServer 확인
# ---------------------------------
reg_vuln = False

try:
    reg_path = r"SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"

    with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, reg_path) as key:
        value, regtype = winreg.QueryValueEx(key, "AutoShareServer")

        if value != 0:
            reg_vuln = True
            diagnosis_result["현황"].append(f"AutoShareServer 값 = {value} (1이면 취약)")
        else:
            diagnosis_result["현황"].append("AutoShareServer 값 = 0 (양호)")

except FileNotFoundError:
    diagnosis_result["현황"].append("AutoShareServer 레지스트리 없음 (기본값 취약 가능)")
    reg_vuln = True

# ---------------------------------
# 2️⃣ 기본 공유 존재 여부 확인
# ---------------------------------
try:
    result = subprocess.run("net share", shell=True, capture_output=True, text=True)

    with open(raw_path / "W-17_share.txt", "w", encoding="utf-8") as f:
        f.write(result.stdout)

    lines = result.stdout.splitlines()

    default_shares = []
    for line in lines:
        if "$" in line:
            parts = line.split()
            if parts:
                share = parts[0]
                if share not in ["IPC$"]:
                    default_shares.append(share)

    if default_shares:
        diagnosis_result["현황"].append(f"기본 공유 존재: {', '.join(default_shares)}")
        share_vuln = True
    else:
        diagnosis_result["현황"].append("불필요한 기본 공유 없음")
        share_vuln = False

except Exception as e:
    diagnosis_result["현황"].append(str(e))
    share_vuln = True

# ---------------------------------
# 3️⃣ 최종 판정
# ---------------------------------
if reg_vuln or share_vuln:
    diagnosis_result["진단결과"] = "취약"
else:
    diagnosis_result["진단결과"] = "양호"

# ---------------------------------
# 결과 저장
# ---------------------------------
with open(result_path / "W-17.json", "w", encoding="utf-8") as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("W-17 점검 완료")
print(f"결과 위치: {result_path}\\W-17.json")
