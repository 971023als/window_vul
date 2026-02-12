import os
import json
import shutil
import subprocess
import ctypes
from pathlib import Path

# -----------------------------
# 관리자 권한 확인
# -----------------------------
def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

if not is_admin():
    print("관리자 권한으로 실행 필요")
    exit(1)

# -----------------------------
# 기본 경로
# -----------------------------
computer_name = os.environ.get("COMPUTERNAME", "UNKNOWN")

raw_path = Path(f"C:\\Windows_{computer_name}_raw")
result_path = Path(f"C:\\Windows_{computer_name}_result")

shutil.rmtree(raw_path, ignore_errors=True)
shutil.rmtree(result_path, ignore_errors=True)

raw_path.mkdir(parents=True, exist_ok=True)
result_path.mkdir(parents=True, exist_ok=True)

# -----------------------------
# 결과 JSON 구조
# -----------------------------
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-03",
    "위험도": "상",
    "진단항목": "불필요한 계정 제거",
    "진단결과": "양호",
    "현황": [],
    "대응방안": "미사용/의심 계정 삭제 또는 비활성화"
}

# -----------------------------
# 기본 허용 계정 (환경별 커스터마이징 가능)
# -----------------------------
allowed_accounts = [
    "Administrator",
    "Guest",
    "DefaultAccount",
    "WDAGUtilityAccount"
]

# -----------------------------
# 계정 목록 수집
# -----------------------------
try:
    output = subprocess.check_output("net user", shell=True, text=True, encoding="cp949", errors="ignore")

    with open(raw_path / "account_list.txt", "w", encoding="utf-8") as f:
        f.write(output)

    # 계정 파싱
    lines = output.splitlines()
    users = []

    for line in lines:
        if "----" in line or "명령을 잘 실행했습니다" in line:
            continue
        if line.strip() == "":
            continue
        if "사용자 계정" in line or "User accounts" in line:
            continue

        parts = line.split()
        for p in parts:
            users.append(p)

    suspicious_accounts = []

    for user in users:
        if user not in allowed_accounts:
            suspicious_accounts.append(user)

    # -----------------------------
    # 판단
    # -----------------------------
    if suspicious_accounts:
        diagnosis_result["진단결과"] = "취약"
        diagnosis_result["현황"].append(f"불필요/확인 필요 계정 발견: {', '.join(suspicious_accounts)}")
    else:
        diagnosis_result["현황"].append("불필요한 계정 발견되지 않음")

except Exception as e:
    diagnosis_result["진단결과"] = "오류"
    diagnosis_result["현황"].append(str(e))

# -----------------------------
# 결과 저장
# -----------------------------
with open(result_path / "W-03.json", "w", encoding="utf-8") as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("W-03 점검 완료")
print(f"결과 위치: {result_path}\\W-03.json")
