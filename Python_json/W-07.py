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

raw_path.mkdir(parents=True, exist_ok=True)
result_path.mkdir(parents=True, exist_ok=True)

# -----------------------------
# 결과 JSON
# -----------------------------
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-07",
    "위험도": "중",
    "진단항목": "Everyone 사용 권한을 익명 사용자에 적용",
    "진단결과": "양호",
    "현황": [],
    "대응방안": "Everyone 사용 권한을 익명 사용자에 적용 정책을 '사용 안 함'으로 설정"
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
# EveryoneIncludesAnonymous = 1 (사용)
# EveryoneIncludesAnonymous = 0 (사용 안 함)
# -----------------------------
try:
    if not policy_file.exists():
        diagnosis_result["진단결과"] = "오류"
        diagnosis_result["현황"].append("보안 정책 파일 export 실패")

    else:
        with open(policy_file, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()

        if "EveryoneIncludesAnonymous = 1" in content:
            diagnosis_result["진단결과"] = "취약"
            diagnosis_result["현황"].append("Everyone 권한이 익명 사용자에 적용됨 (사용 상태)")
        elif "EveryoneIncludesAnonymous = 0" in content:
            diagnosis_result["현황"].append("Everyone 권한 익명 사용자 적용 비활성화 상태")
        else:
            diagnosis_result["진단결과"] = "확인필요"
            diagnosis_result["현황"].append("정책 값을 확인할 수 없음")

except Exception as e:
    diagnosis_result["진단결과"] = "오류"
    diagnosis_result["현황"].append(str(e))

# -----------------------------
# 결과 저장
# -----------------------------
with open(result_path / "W-07.json", "w", encoding="utf-8") as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("W-07 점검 완료")
print(f"결과 위치: {result_path}\\W-07.json")
