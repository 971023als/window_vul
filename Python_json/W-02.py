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
# 기본 경로 설정
# -----------------------------
computer_name = os.environ.get("COMPUTERNAME", "UNKNOWN")

raw_path = Path(f"C:\\Windows_{computer_name}_raw")
result_path = Path(f"C:\\Windows_{computer_name}_result")

# 기존 삭제 후 재생성
shutil.rmtree(raw_path, ignore_errors=True)
shutil.rmtree(result_path, ignore_errors=True)

raw_path.mkdir(parents=True, exist_ok=True)
result_path.mkdir(parents=True, exist_ok=True)

# -----------------------------
# 진단 결과 기본 구조
# -----------------------------
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-02",
    "위험도": "상",
    "진단항목": "Guest 계정 비활성화",
    "진단결과": "양호",
    "현황": [],
    "대응방안": "Guest 계정 비활성화 (net user guest /active:no)"
}

# -----------------------------
# 시스템 정보 수집
# -----------------------------
with open(raw_path / "systeminfo.txt", "w", encoding="utf-8") as f:
    subprocess.run("systeminfo", stdout=f, shell=True)

# 로컬 보안정책 export
subprocess.run(f'secedit /export /cfg "{raw_path}\\secpol.txt"', shell=True)

# -----------------------------
# Guest 계정 상태 확인
# -----------------------------
try:
    cmd = "net user guest"
    output = subprocess.check_output(cmd, shell=True, text=True, encoding="cp949", errors="ignore")

    # raw 증적 저장
    with open(raw_path / "guest_account.txt", "w", encoding="utf-8") as f:
        f.write(output)

    # 활성 여부 판단 (한글/영문 둘다 대응)
    if ("Account active               Yes" in output or 
        "계정 활성               예" in output):
        
        diagnosis_result["진단결과"] = "취약"
        diagnosis_result["현황"].append("Guest 계정이 활성화되어 있음")

    else:
        diagnosis_result["현황"].append("Guest 계정이 비활성화 상태")

except Exception as e:
    diagnosis_result["진단결과"] = "오류"
    diagnosis_result["현황"].append(str(e))

# -----------------------------
# 결과 JSON 저장
# -----------------------------
with open(result_path / "W-02.json", "w", encoding="utf-8") as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("W-02 Guest 계정 점검 완료")
print(f"결과 파일: {result_path}\\W-02.json")
