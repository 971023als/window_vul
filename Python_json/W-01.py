import os
import json
import shutil
import subprocess
import ctypes
from pathlib import Path

# ---------------------------
# 관리자 권한 체크 (Windows)
# ---------------------------
def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

if not is_admin():
    print("관리자 권한으로 실행 필요")
    exit(1)

# ---------------------------
# 기본 정보
# ---------------------------
computer_name = os.environ.get("COMPUTERNAME", "UNKNOWN")

raw_path = Path(f"C:\\Windows_{computer_name}_raw")
result_path = Path(f"C:\\Windows_{computer_name}_result")

# 기존 폴더 삭제
shutil.rmtree(raw_path, ignore_errors=True)
shutil.rmtree(result_path, ignore_errors=True)

# 폴더 생성
raw_path.mkdir(parents=True, exist_ok=True)
result_path.mkdir(parents=True, exist_ok=True)

# ---------------------------
# 진단 결과 JSON 구조
# ---------------------------
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-01",
    "위험도": "상",
    "진단항목": "Administrator 계정 이름 변경",
    "진단결과": "양호",
    "현황": [],
    "대응방안": "기본 Administrator 계정명 변경 및 복잡한 비밀번호 적용"
}

# ---------------------------
# 시스템 정보 수집
# ---------------------------
with open(raw_path / "systeminfo.txt", "w", encoding="utf-8") as f:
    subprocess.run("systeminfo", stdout=f, shell=True)

# 로컬 보안 정책 export
subprocess.run(f'secedit /export /cfg "{raw_path}\\secpol.txt"', shell=True)

# ---------------------------
# Administrator 실제 이름 확인 (SID 기반)
# ---------------------------
try:
    cmd = 'wmic useraccount where "sid like \'S-1-5-21%%-500\'" get name'
    output = subprocess.check_output(cmd, shell=True, text=True)

    lines = [l.strip() for l in output.split("\n") if l.strip() and "Name" not in l]

    if not lines:
        diagnosis_result["진단결과"] = "N/A"
        diagnosis_result["현황"].append("Administrator 계정 확인 실패")

    else:
        admin_name = lines[0]
        diagnosis_result["현황"].append(f"현재 관리자 계정명: {admin_name}")

        if admin_name.lower() == "administrator":
            diagnosis_result["진단결과"] = "취약"
            diagnosis_result["현황"].append("기본 Administrator 이름 그대로 사용중")
        else:
            diagnosis_result["현황"].append("Administrator 계정명 변경됨")

except Exception as e:
    diagnosis_result["진단결과"] = "오류"
    diagnosis_result["현황"].append(str(e))

# ---------------------------
# JSON 결과 저장
# ---------------------------
with open(result_path / "W-01.json", "w", encoding="utf-8") as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("W-01 점검 완료")
print(result_path / "W-01.json")
