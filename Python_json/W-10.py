import os
import json
import subprocess
import ctypes
from pathlib import Path
import winreg

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
# 결과 JSON
# -----------------------------
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-10",
    "위험도": "중",
    "진단항목": "마지막 사용자 이름 표시 안 함",
    "진단결과": "양호",
    "현황": [],
    "대응방안": "로그온 화면에 마지막 사용자 이름 표시 안 함 설정"
}

# -----------------------------
# 레지스트리 점검
# -----------------------------
try:
    reg_path = r"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

    key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, reg_path)
    value, regtype = winreg.QueryValueEx(key, "DontDisplayLastUserName")

    diagnosis_result["현황"].append(f"DontDisplayLastUserName 값: {value}")

    if value == 1:
        diagnosis_result["진단결과"] = "양호"
        diagnosis_result["현황"].append("마지막 사용자 이름 표시 안 함 설정 적용됨")
    else:
        diagnosis_result["진단결과"] = "취약"
        diagnosis_result["현황"].append("마지막 사용자 이름 표시 설정 미흡")

except FileNotFoundError:
    diagnosis_result["진단결과"] = "취약"
    diagnosis_result["현황"].append("레지스트리 값이 존재하지 않음 (미설정)")

except Exception as e:
    diagnosis_result["진단결과"] = "오류"
    diagnosis_result["현황"].append(str(e))

# -----------------------------
# 결과 저장
# -----------------------------
with open(result_path / "W-10.json", "w", encoding="utf-8") as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("W-10 점검 완료")
print(f"결과 위치: {result_path}\\W-10.json")
