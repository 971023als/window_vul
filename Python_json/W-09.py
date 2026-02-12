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
# 기본 경로 설정
# -----------------------------
computer_name = os.environ.get("COMPUTERNAME", "UNKNOWN")

raw_path = Path(f"C:\\Windows_{computer_name}_raw")
result_path = Path(f"C:\\Windows_{computer_name}_result")

raw_path.mkdir(parents=True, exist_ok=True)
result_path.mkdir(parents=True, exist_ok=True)

# -----------------------------
# 결과 JSON 구조
# -----------------------------
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-09",
    "위험도": "상",
    "진단항목": "비밀번호 관리 정책 설정",
    "진단결과": "양호",
    "현황": [],
    "대응방안": "비밀번호 복잡성, 길이, 사용기간 정책 적용"
}

# -----------------------------
# 보안 정책 export
# -----------------------------
policy_file = raw_path / "Local_Security_Policy.txt"

subprocess.run([
    "secedit",
    "/export",
    "/cfg",
    str(policy_file)
], capture_output=True)

# -----------------------------
# 기준값
# -----------------------------
MIN_LENGTH = 8
MAX_AGE = 90
MIN_AGE = 1
HISTORY = 4

# -----------------------------
# 정책 점검
# -----------------------------
try:
    if not policy_file.exists():
        diagnosis_result["진단결과"] = "오류"
        diagnosis_result["현황"].append("보안 정책 export 실패")

    else:
        with open(policy_file, "r", encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()

        complexity = None
        min_length = None
        max_age = None
        min_age = None
        history = None

        for line in lines:
            if "PasswordComplexity" in line:
                complexity = int(line.split("=")[1].strip())
            if "MinimumPasswordLength" in line:
                min_length = int(line.split("=")[1].strip())
            if "MaximumPasswordAge" in line:
                max_age = int(line.split("=")[1].strip())
            if "MinimumPasswordAge" in line:
                min_age = int(line.split("=")[1].strip())
            if "PasswordHistorySize" in line:
                history = int(line.split("=")[1].strip())

        # -------------------------
        # 현황 기록
        # -------------------------
        diagnosis_result["현황"].append(f"복잡성 사용: {complexity}")
        diagnosis_result["현황"].append(f"최소 길이: {min_length}")
        diagnosis_result["현황"].append(f"최대 사용기간: {max_age}")
        diagnosis_result["현황"].append(f"최소 사용기간: {min_age}")
        diagnosis_result["현황"].append(f"암호 기억 개수: {history}")

        # -------------------------
        # 판정
        # -------------------------
        if (
            complexity != 1 or
            min_length is None or min_length < MIN_LENGTH or
            max_age is None or max_age > MAX_AGE or
            min_age is None or min_age < MIN_AGE or
            history is None or history < HISTORY
        ):
            diagnosis_result["진단결과"] = "취약"
            diagnosis_result["현황"].append("비밀번호 정책 기준 미충족")
        else:
            diagnosis_result["현황"].append("비밀번호 정책 기준 충족")

except Exception as e:
    diagnosis_result["진단결과"] = "오류"
    diagnosis_result["현황"].append(str(e))

# -----------------------------
# 결과 저장
# -----------------------------
with open(result_path / "W-09.json", "w", encoding="utf-8") as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("W-09 점검 완료")
print(f"결과 위치: {result_path}\\W-09.json")
