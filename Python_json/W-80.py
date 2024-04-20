import json
import os
import subprocess
from pathlib import Path
import ctypes

def check_admin_rights():
    """Check if the script is running with administrative privileges."""
    try:
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
    except Exception:
        return False

def setup_directories(base_dir, dirs):
    """Create and clean directories for storing raw and result data."""
    for d in dirs:
        dir_path = base_dir / d
        if dir_path.exists():
            for item in dir_path.iterdir():
                if item.is_dir():
                    setup_directories(item, [])
                else:
                    item.unlink()
        else:
            dir_path.mkdir(parents=True, exist_ok=True)
    return [base_dir / d for d in dirs]

def export_security_policy(output_path):
    """Export local security settings to a file."""
    subprocess.run(f'secedit /export /cfg "{output_path}"', check=True)

def analyze_security_settings(file_path):
    """Analyze security settings from exported configuration."""
    with open(file_path, 'r') as file:
        policies = file.readlines()

    conditions_met = any("MaximumPasswordAge" in line for line in policies if "90" in line)
    return conditions_met

def save_results(data, output_path):
    """Save the results to a JSON file."""
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

def main():
    if not check_admin_rights():
        print("관리자 권한으로 실행해야 합니다.")
        return

    base_dir = Path(f"C:/Window_{os.getenv('COMPUTERNAME', 'UNKNOWN_PC')}")
    raw_dir, result_dir = setup_directories(base_dir, ['raw', 'result'])

    # Export and analyze security policies
    policy_path = raw_dir / "Local_Security_Policy.txt"
    export_security_policy(policy_path)
    conditions_met = analyze_security_settings(policy_path)

    # Define JSON structure
    security_data = {
        "분류": "보안관리",
        "코드": "W-80",
        "위험도": "상",
        "진단 항목": "컴퓨터 계정 암호 최대 사용 기간",
        "진단 결과": "양호" if conditions_met else "취약",
        "현황": [],
        "대응방안": "컴퓨터 계정 암호 최대 사용 기간"
    }
    
    if not conditions_met:
        security_data["현황"].append("컴퓨터 계정 암호 최대 사용 기간이 90일 미만입니다.")

    # Save results to JSON
    json_path = result_dir / f"W-80_{os.getenv('COMPUTERNAME', 'UNKNOWN_PC')}_diagnostic_results.json"
    save_results(security_data, json_path)

    print(f"진단 결과가 저장되었습니다: {json_path}")
    print("스크립트가 완료되었습니다.")

if __name__ == "__main__":
    main()
