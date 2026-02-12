import os
import json
import subprocess
import ctypes
from pathlib import Path

# -------------------------------------------------
# 관리자 권한 체크
# -------------------------------------------------
def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

if not is_admin():
    print("관리자 권한으로 실행 필요")
    exit(1)

# -------------------------------------------------
# 기본 경로
# -------------------------------------------------
computer_name = os.environ.get("COMPUTERNAME", "UNKNOWN")

raw_path = Path(f"C:\\Windows_{computer_name}_raw")
result_path = Path(f"C:\\Windows_{computer_name}_result")

raw_path.mkdir(parents=True, exist_ok=True)
result_path.mkdir(parents=True, exist_ok=True)

# -------------------------------------------------
# 결과 JSON 구조
# -------------------------------------------------
diagnosis_result = {
    "분류": "서비스관리",
    "코드": "W-22",
    "위험도": "상",
    "진단항목": "FTP 디렉토리 접근권한 설정",
    "진단결과": "양호",
    "현황": [],
    "대응방안": "FTP 홈 디렉터리 Everyone 권한 제거"
}

weak_found = False

# -------------------------------------------------
# 1️⃣ IIS FTP 경로 확인
# -------------------------------------------------
print("FTP 홈디렉토리 탐색 중...")

ftp_paths = []

default_paths = [
    r"C:\inetpub\ftproot",
    r"C:\FTP",
    r"D:\FTP"
]

for p in default_paths:
    if Path(p).exists():
        ftp_paths.append(p)

# IIS 설정파일에서 경로 탐색
iis_config = Path(r"C:\Windows\System32\inetsrv\config\applicationHost.config")

if iis_config.exists():
    try:
        content = iis_config.read_text(errors="ignore")
        with open(raw_path / "W-22_iis_raw.txt", "w", encoding="utf-8") as f:
            f.write(content)

        import re
        matches = re.findall(r'physicalPath="([^"]+)"', content)
        for m in matches:
            if "ftp" in m.lower():
                ftp_paths.append(m)

    except:
        pass

ftp_paths = list(set(ftp_paths))

if not ftp_paths:
    diagnosis_result["현황"].append("FTP 홈 디렉터리 발견되지 않음 (FTP 미사용)")
else:
    diagnosis_result["현황"].append(f"FTP 디렉터리 발견: {ftp_paths}")

# -------------------------------------------------
# 2️⃣ Everyone 권한 검사
# -------------------------------------------------
for ftp_dir in ftp_paths:
    if not Path(ftp_dir).exists():
        continue

    try:
        result = subprocess.run(
            ["icacls", ftp_dir],
            capture_output=True,
            text=True
        )

        acl_output = result.stdout

        with open(raw_path / f"W-22_acl_{os.path.basename(ftp_dir)}.txt", "w", encoding="utf-8") as f:
            f.write(acl_output)

        if "Everyone" in acl_output:
            weak_found = True
            diagnosis_result["현황"].append(f"[취약] {ftp_dir} → Everyone 권한 존재")
        else:
            diagnosis_result["현황"].append(f"[양호] {ftp_dir} → Everyone 권한 없음")

    except Exception as e:
        diagnosis_result["현황"].append(f"{ftp_dir} ACL 확인 실패")

# -------------------------------------------------
# 최종 판정
# -------------------------------------------------
if weak_found:
    diagnosis_result["진단결과"] = "취약"
else:
    if ftp_paths:
        diagnosis_result["진단결과"] = "양호"
    else:
        diagnosis_result["진단결과"] = "양호"

# -------------------------------------------------
# 결과 저장
# -------------------------------------------------
with open(result_path / "W-22.json", "w", encoding="utf-8") as f:
    json.dump(diagnosis_result, f, ensure_ascii=False, indent=4)

print("W-22 점검 완료")
print(f"결과 위치: {result_path}\\W-22.json")
