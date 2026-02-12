import os
import json
import winreg
import ctypes
from pathlib import Path

# ---------------------------------
# 관리자 권한 체크
# ---------------------------------
def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

if not is_admin():
    print("관리자 권한으로 실행 필요")
    exit(1)

# ---------------------------------
# 기본 경로 생성
# ---------------------------------
computer_name = os.environ.get("COMPUTERNAME", "UNKNOWN")

raw_path = Path(f"C:\\Windows_{computer_name}_raw")
result_path = Path(f"C:\\Windows_{computer_name}_result")

raw_path.mkdir(parents=True, exist_ok=True)
result_path.mkdir(parents=True, exist_ok=True)

# ---------------------------------
# 결과 JSON 구조
# ---------------------------------
diagnosis_result = {
    "분류": "서비스관리",
    "코드": "W-20",
    "위험도": "상",
    "진단항목": "NetBIOS 바인딩 서비스 구동 점검",
    "진단결과": "양호",
    "현황": [],
    "대응방안": "TCP/IP NetBIOS 바인딩 비활성화"
}

# ---------------------------------
# 레지스트리 NetBIOS 확인
# ---------------------------------
reg_path = r"SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces"

try:
    key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, reg_path)

    i = 0
    weak_found = False

    while True:
        try:
            subkey_name = winreg.EnumKey(key, i)
            subkey = winreg.OpenKey(key, subkey_name)

            try:
                value, _ = winreg.QueryValueEx(subkey, "NetbiosOptions")
            except FileNotFoundError:
                value = 0  # 기본값 (DHCP 따름)

            # RAW 기록
            with open(raw_path / "W-20_netbios_raw.txt", "a", encoding="utf-8") as f:
                f.write(f"{subkey_name} = {value}\n")

            if value != 2:
                weak_found = True
                diagnosis_result["현황"].append(
                    f"{subkey_name} → NetBIOS 활성 상태 (값:{value})"
                )

            winreg.CloseKey(subkey)
            i += 1

        except OSError:
            break

    winreg.CloseKey(key)

    if weak_found:
        diagnosis_result["진단결과"] = "취약"
    else:
        diagnosis_result["현황"].append("모든 NIC NetBIOS 비활성화 상태")
        diagnosis_result["진단결과"] = "양호"

except Exception as e:
    diagnosis_result["진단결과"] = "취약"
    diagnosis_result["현황"].append(f"레지스트리 확인 실패: {str(e)}")

# ---------------------------------
# 결과 저장
# ---------------------------------
with open(result_path / "W-20.json", "w", encoding="utf-8") as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("W-20 점검 완료")
print(f"결과 위치: {result_path}\\W-20.json")
