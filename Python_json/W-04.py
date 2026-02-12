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

shutil.rmtree(raw_path, ignore_errors=True)
shutil.rmtree(result_path, ignore_errors=True)

raw_path.mkdir(parents=True, exist_ok=True)
result_path.mkdir(parents=True, exist_ok=True)

# -----------------------------
# 결과 JSON
# -----------------------------
diagnosis_result = {
    "분류": "계정관리",
    "코드": "W-04",
    "위험도": "상",
    "진단항목": "계정 잠금 임계값 설정",
    "진단결과": "양호",
    "현황": [],
    "대응방안": "계정 잠금 임계값 5회 이하 설정"
}

# -----------------------------
# 정책 export
# -----------------------------
policy_file = raw_path / "secpol.txt"

try:
    subprocess.run(
        f'secedit /export /cfg "{policy_file}"',
        shell=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )

    if not policy_file.exists():
        diagnosis_result["진단결과"] = "오류"
        diagnosis_result["현황"].append("보안정책 export 실패")
    else:
        with open(policy_file, "r", encoding="utf-16", errors="ignore") as f:
            content = f.read()

        threshold = None

        for line in content.splitlines():
            if "LockoutBadCount" in line:
                try:
                    threshold = int(line.split("=")[1].strip())
                except:
                    pass

        # -----------------------------
        # 판단 로직
        # -----------------------------
        if threshold is None:
            diagnosis_result["진단결과"] = "취약"
            diagnosis_result["현황"].append("계정 잠금 임계값 설정 없음")
        else:
            diagnosis_result["현황"].append(f"계정 잠금 임계값: {threshold}")

            if threshold == 0:
                diagnosis_result["진단결과"] = "취약"
                diagnosis_result["현황"].append("잠금 기능 비활성화 상태")
            elif threshold > 5:
                diagnosis_result["진단결과"] = "취약"
                diagnosis_result["현황"].append("기준 초과 (5회 이하 필요)")
            else:
                diagnosis_result["현황"].append("보안 기준 충족")

except Exception as e:
    diagnosis_result["진단결과"] = "오류"
    diagnosis_result["현황"].append(str(e))

# -----------------------------
# 결과 저장
# -----------------------------
with open(result_path / "W-04.json", "w", encoding="utf-8") as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("W-04 점검 완료")
print(f"결과 위치: {result_path}\\W-04.json")
