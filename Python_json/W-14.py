import os
import json
import subprocess
import ctypes
from pathlib import Path

# -----------------------------
# 관리자 권한 체크
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
    "코드": "W-14",
    "위험도": "중",
    "진단항목": "원격터미널 접속 가능한 사용자 그룹 제한",
    "진단결과": "양호",
    "현황": [],
    "대응방안": "Remote Desktop Users 그룹에 최소 계정만 유지"
}

# -----------------------------
# Remote Desktop Users 조회
# -----------------------------
try:
    cmd = "net localgroup \"Remote Desktop Users\""
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)

    output = result.stdout.splitlines()

    members = []
    start = False

    for line in output:
        if "----" in line:
            start = True
            continue
        if start:
            if "명령을 잘 실행했습니다" in line or "command completed successfully" in line.lower():
                break
            if line.strip():
                members.append(line.strip())

    # 저장
    with open(raw_path / "rdp_users.txt", "w", encoding="utf-8") as f:
        f.write("\n".join(members))

    # -----------------------------
    # 판정 로직
    # -----------------------------
    if len(members) == 0:
        diagnosis_result["진단결과"] = "취약"
        diagnosis_result["현황"].append("Remote Desktop Users 그룹에 계정 없음 (관리통제 미흡)")
    else:
        diagnosis_result["현황"].append(f"등록 계정: {', '.join(members)}")

        # Administrator 외 전용계정 존재 여부
        non_admin = [
            m for m in members
            if "administrator" not in m.lower()
        ]

        if len(non_admin) == 0:
            diagnosis_result["진단결과"] = "취약"
            diagnosis_result["현황"].append("Administrator 외 전용 원격접속 계정 없음")
        else:
            diagnosis_result["진단결과"] = "양호"
            diagnosis_result["현황"].append("전용 원격접속 계정 존재 및 최소 권한 운영")

except Exception as e:
    diagnosis_result["진단결과"] = "오류"
    diagnosis_result["현황"].append(str(e))

# -----------------------------
# 결과 저장
# -----------------------------
with open(result_path / "W-14.json", "w", encoding="utf-8") as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("W-14 점검 완료")
print(f"결과 위치: {result_path}\\W-14.json")
