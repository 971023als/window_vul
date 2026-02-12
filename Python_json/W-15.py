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
    "분류": "서비스관리",
    "코드": "W-15",
    "위험도": "상",
    "진단항목": "사용자 개인키 사용 시 암호 입력",
    "진단결과": "양호",
    "현황": [],
    "대응방안": "강력한 키 보호: 키 사용할 때마다 암호 입력 설정"
}

# -----------------------------
# 레지스트리 조회
# -----------------------------
try:
    reg_cmd = r'reg query "HKLM\SOFTWARE\Policies\Microsoft\Cryptography" /v ForceKeyProtection'
    result = subprocess.run(reg_cmd, shell=True, capture_output=True, text=True)

    with open(raw_path / "W-15_reg.txt", "w", encoding="utf-8") as f:
        f.write(result.stdout + result.stderr)

    if "ForceKeyProtection" not in result.stdout:
        diagnosis_result["진단결과"] = "취약"
        diagnosis_result["현황"].append("강력한 키 보호 정책이 설정되지 않음")

    else:
        value_line = [line for line in result.stdout.splitlines() if "ForceKeyProtection" in line]

        if value_line:
            value = value_line[0].split()[-1]

            # 16진 → 10진 변환
            try:
                int_value = int(value, 16)
            except:
                int_value = int(value)

            if int_value == 2:
                diagnosis_result["진단결과"] = "양호"
                diagnosis_result["현황"].append("개인키 사용 시 매번 암호 입력 설정됨")
            else:
                diagnosis_result["진단결과"] = "취약"
                diagnosis_result["현황"].append(f"현재 설정값: {int_value} (매번 암호 입력 아님)")
        else:
            diagnosis_result["진단결과"] = "취약"
            diagnosis_result["현황"].append("레지스트리 값 확인 불가")

except Exception as e:
    diagnosis_result["진단결과"] = "오류"
    diagnosis_result["현황"].append(str(e))

# -----------------------------
# 결과 저장
# -----------------------------
with open(result_path / "W-15.json", "w", encoding="utf-8") as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("W-15 점검 완료")
print(f"결과 위치: {result_path}\\W-15.json")
