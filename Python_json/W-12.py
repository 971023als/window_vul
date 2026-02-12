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
# 결과 JSON
# -----------------------------
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-12",
    "위험도": "중",
    "진단항목": "익명 SID/이름 변환 허용 해제",
    "진단결과": "양호",
    "현황": [],
    "대응방안": "네트워크 액세스: 익명 SID/이름 변환 허용 → 사용 안 함 설정"
}

# -----------------------------
# 보안 정책 export
# -----------------------------
policy_file = raw_path / "secpol.cfg"

subprocess.run([
    "secedit", "/export",
    "/cfg", str(policy_file)
], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# -----------------------------
# 정책 확인
# -----------------------------
try:
    with open(policy_file, "r", encoding="utf-16", errors="ignore") as f:
        lines = f.readlines()

    setting_found = False

    for line in lines:
        if "SeAllowAnonymousSIDLookup" in line:
            setting_found = True
            value = line.split("=")[1].strip()

            diagnosis_result["현황"].append(f"현재 설정값: {value}")

            if value == "0":
                diagnosis_result["진단결과"] = "양호"
                diagnosis_result["현황"].append("익명 SID/이름 변환 허용 비활성화 상태")
            else:
                diagnosis_result["진단결과"] = "취약"
                diagnosis_result["현황"].append("익명 SID/이름 변환 허용 활성화 상태")

    if not setting_found:
        diagnosis_result["진단결과"] = "확인불가"
        diagnosis_result["현황"].append("정책 값을 찾을 수 없음")

except Exception as e:
    diagnosis_result["진단결과"] = "오류"
    diagnosis_result["현황"].append(str(e))

# -----------------------------
# 결과 저장
# -----------------------------
with open(result_path / "W-12.json", "w", encoding="utf-8") as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("W-12 점검 완료")
print(f"결과 위치: {result_path}\\W-12.json")
