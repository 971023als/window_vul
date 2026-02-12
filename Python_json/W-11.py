import os
import json
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

raw_path.mkdir(parents=True, exist_ok=True)
result_path.mkdir(parents=True, exist_ok=True)

# -----------------------------
# 결과 JSON
# -----------------------------
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-11",
    "위험도": "중",
    "진단항목": "로컬 로그온 허용 계정 최소화",
    "진단결과": "양호",
    "현황": [],
    "대응방안": "Administrators, IUSR 외 계정 제거"
}

# -----------------------------
# 보안정책 export
# -----------------------------
policy_file = raw_path / "secpol.cfg"

subprocess.run([
    "secedit", "/export",
    "/cfg", str(policy_file)
], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# -----------------------------
# 정책 파싱
# -----------------------------
allowed_accounts = []

try:
    with open(policy_file, "r", encoding="utf-16", errors="ignore") as f:
        for line in f:
            if "SeInteractiveLogonRight" in line:
                parts = line.strip().split("=")
                if len(parts) > 1:
                    accounts = parts[1].split(",")
                    allowed_accounts = [a.strip() for a in accounts]

    diagnosis_result["현황"].append(f"로컬 로그온 허용 계정: {allowed_accounts}")

    weak_accounts = []

    for acc in allowed_accounts:
        acc_lower = acc.lower()

        if "administrators" in acc_lower:
            continue
        elif "iusr" in acc_lower:
            continue
        elif acc == "":
            continue
        else:
            weak_accounts.append(acc)

    if weak_accounts:
        diagnosis_result["진단결과"] = "취약"
        diagnosis_result["현황"].append(f"불필요 계정 존재: {weak_accounts}")
    else:
        diagnosis_result["현황"].append("허용된 계정만 존재")

except Exception as e:
    diagnosis_result["진단결과"] = "오류"
    diagnosis_result["현황"].append(str(e))

# -----------------------------
# 결과 저장
# -----------------------------
with open(result_path / "W-11.json", "w", encoding="utf-8") as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("W-11 점검 완료")
print(f"결과 위치: {result_path}\\W-11.json")
