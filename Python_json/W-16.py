import os
import json
import subprocess
import ctypes
from pathlib import Path

# -----------------------------------
# 관리자 권한 체크
# -----------------------------------
def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

if not is_admin():
    print("관리자 권한으로 실행 필요")
    exit(1)

# -----------------------------------
# 기본 경로
# -----------------------------------
computer_name = os.environ.get("COMPUTERNAME", "UNKNOWN")

raw_path = Path(f"C:\\Windows_{computer_name}_raw")
result_path = Path(f"C:\\Windows_{computer_name}_result")

raw_path.mkdir(parents=True, exist_ok=True)
result_path.mkdir(parents=True, exist_ok=True)

# -----------------------------------
# 결과 JSON
# -----------------------------------
diagnosis_result = {
    "분류": "서비스관리",
    "코드": "W-16",
    "위험도": "상",
    "진단항목": "공유 권한 및 사용자 그룹 설정",
    "진단결과": "양호",
    "현황": [],
    "대응방안": "공유폴더 Everyone 권한 제거 후 필요한 계정만 부여"
}

# -----------------------------------
# 기본 관리자 공유 제외 목록
# -----------------------------------
default_shares = ["C$", "D$", "ADMIN$", "IPC$", "PRINT$"]

try:
    # 공유 목록 조회
    share_cmd = "net share"
    result = subprocess.run(share_cmd, shell=True, capture_output=True, text=True)

    with open(raw_path / "W-16_share_list.txt", "w", encoding="utf-8") as f:
        f.write(result.stdout)

    lines = result.stdout.splitlines()

    share_list = []
    for line in lines:
        if "Disk" in line or "IPC" in line:
            parts = line.split()
            if parts:
                share_list.append(parts[0])

    # 일반 공유만 필터
    normal_shares = [s for s in share_list if s.upper() not in default_shares]

    if not normal_shares:
        diagnosis_result["진단결과"] = "양호"
        diagnosis_result["현황"].append("일반 공유 폴더 없음")
    else:
        vulnerable_found = False

        for share in normal_shares:
            perm_cmd = f'net share "{share}"'
            perm_result = subprocess.run(perm_cmd, shell=True, capture_output=True, text=True)

            with open(raw_path / f"W-16_{share}.txt", "w", encoding="utf-8") as f:
                f.write(perm_result.stdout)

            if "Everyone" in perm_result.stdout:
                vulnerable_found = True
                diagnosis_result["현황"].append(f"{share} 공유폴더에 Everyone 권한 존재")

        if vulnerable_found:
            diagnosis_result["진단결과"] = "취약"
        else:
            diagnosis_result["현황"].append("공유폴더에 Everyone 권한 없음")
            diagnosis_result["진단결과"] = "양호"

except Exception as e:
    diagnosis_result["진단결과"] = "오류"
    diagnosis_result["현황"].append(str(e))

# -----------------------------------
# 결과 저장
# -----------------------------------
with open(result_path / "W-16.json", "w", encoding="utf-8") as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("W-16 점검 완료")
print(f"결과 위치: {result_path}\\W-16.json")
