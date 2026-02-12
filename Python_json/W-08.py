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
# 경로 설정
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
    "코드": "W-08",
    "위험도": "중",
    "진단항목": "계정 잠금 기간 설정",
    "진단결과": "양호",
    "현황": [],
    "대응방안": "계정 잠금 기간 및 초기화 시간 60분 이상 설정"
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
# 정책 점검
# LockoutDuration
# ResetLockoutCount
# -----------------------------
try:
    if not policy_file.exists():
        diagnosis_result["진단결과"] = "오류"
        diagnosis_result["현황"].append("보안 정책 export 실패")

    else:
        with open(policy_file, "r", encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()

        lockout_duration = None
        reset_duration = None

        for line in lines:
            if "LockoutDuration" in line:
                lockout_duration = int(line.split("=")[1].strip())
            if "ResetLockoutCount" in line:
                reset_duration = int(line.split("=")[1].strip())

        # -------------------------
        # 판정
        # -------------------------
        if lockout_duration is None or reset_duration is None:
            diagnosis_result["진단결과"] = "확인필요"
            diagnosis_result["현황"].append("계정 잠금 정책 값을 확인할 수 없음")

        else:
            diagnosis_result["현황"].append(f"계정 잠금 기간: {lockout_duration}분")
            diagnosis_result["현황"].append(f"잠금 초기화 기간: {reset_duration}분")

            if lockout_duration < 60 or reset_duration < 60:
                diagnosis_result["진단결과"] = "취약"
                diagnosis_result["현황"].append("60분 미만 설정됨")
            else:
                diagnosis_result["현황"].append("정책 기준 충족")

except Exception as e:
    diagnosis_result["진단결과"] = "오류"
    diagnosis_result["현황"].append(str(e))

# -----------------------------
# 결과 저장
# -----------------------------
with open(result_path / "W-08.json", "w", encoding="utf-8") as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("W-08 점검 완료")
print(f"결과 위치: {result_path}\\W-08.json")
