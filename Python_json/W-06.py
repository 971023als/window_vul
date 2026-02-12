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
    "코드": "W-06",
    "위험도": "상",
    "진단항목": "관리자 그룹에 최소한의 사용자 포함",
    "진단결과": "양호",
    "현황": [],
    "대응방안": "Administrators 그룹 내 불필요 계정 제거"
}

# -----------------------------
# 관리자 그룹 조회
# -----------------------------
try:
    result = subprocess.run(
        ["net", "localgroup", "Administrators"],
        capture_output=True,
        text=True,
        shell=True
    )

    output = result.stdout
    with open(raw_path / "admin_group.txt", "w", encoding="utf-8") as f:
        f.write(output)

    lines = output.splitlines()

    members = []
    start = False

    for line in lines:
        if "----" in line:
            start = True
            continue
        if start:
            if "명령을 잘 실행했습니다" in line or "The command completed successfully" in line:
                break
            user = line.strip()
            if user:
                members.append(user)

    # 기본 관리자 계정 필터
    base_admin = ["Administrator"]
    real_admins = [m for m in members if m not in base_admin]

    diagnosis_result["현황"].append(f"관리자 그룹 구성원: {', '.join(members)}")

    if len(real_admins) > 1:
        diagnosis_result["진단결과"] = "취약"
        diagnosis_result["현황"].append("불필요한 관리자 계정 다수 존재")
    else:
        diagnosis_result["현황"].append("관리자 최소 구성 유지")

except Exception as e:
    diagnosis_result["진단결과"] = "오류"
    diagnosis_result["현황"].append(str(e))

# -----------------------------
# 결과 저장
# -----------------------------
with open(result_path / "W-06.json", "w", encoding="utf-8") as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("W-06 점검 완료")
print(f"결과 위치: {result_path}\\W-06.json")
