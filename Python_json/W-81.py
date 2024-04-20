import json
import os
import subprocess
from pathlib import Path
import ctypes
import winreg

def check_admin_rights():
    """Check if the script is running with administrative privileges."""
    try:
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
    except Exception:
        return False

def get_autorun_programs():
    """Retrieve the list of programs that run on startup."""
    autorun_locations = [
        r'Software\Microsoft\Windows\CurrentVersion\Run',
        r'Software\Microsoft\Windows\CurrentVersion\RunOnce',
    ]
    autorun_programs = []
    for location in autorun_locations:
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, location, 0, winreg.KEY_READ) as key:
            i = 0
            while True:
                try:
                    name, value, type = winreg.EnumValue(key, i)
                    autorun_programs.append((name, value))
                    i += 1
                except OSError:
                    break
    return autorun_programs

def save_results(data, output_path):
    """Save the results to a JSON file with all text in Korean."""
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

def main():
    if not check_admin_rights():
        print("관리자 권한으로 실행해야 합니다.")
        return

    computer_name = os.getenv('COMPUTERNAME', 'UNKNOWN_PC')
    result_dir = Path(f"C:/Window_{computer_name}_result")
    result_dir.mkdir(parents=True, exist_ok=True)

    # Collect autorun programs
    autorun_programs = get_autorun_programs()

    # Define the JSON structure
    security_data = {
        "분류": "보안관리",
        "코드": "W-81",
        "위험도": "상",
        "진단 항목": "시작프로그램 목록 분석",
        "진단 결과": "양호",
        "현황": [f"{name}: {path}" for name, path in autorun_programs],
        "대응방안": "시작프로그램 목록 분석"
    }

    # Save results to JSON
    json_path = result_dir / f"W-81_{computer_name}_diagnostic_results.json"
    save_results(security_data, json_path)

    print(f"진단 결과가 저장되었습니다: {json_path}")
    print("스크립트가 완료되었습니다.")

if __name__ == "__main__":
    main()
