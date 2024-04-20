import os
import subprocess
import json
import ctypes

def is_admin():
    """Check if the program is running as administrator."""
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except Exception:
        return False

def setup_environment(computer_name):
    """Prepare directories for data storage."""
    raw_dir = f"C:\\Window_{computer_name}_raw"
    result_dir = f"C:\\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def check_scheduled_tasks():
    """Check the system for scheduled tasks."""
    try:
        tasks = subprocess.check_output("schtasks /query", shell=True, text=True, encoding='utf-8')
        if "There are no entries in the list" in tasks:
            return None
        return tasks
    except subprocess.CalledProcessError:
        return None

def main():
    if not is_admin():
        print("이 스크립트는 관리자 권한으로 실행되어야 합니다.")
        return
    
    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_environment(computer_name)
    
    tasks = check_scheduled_tasks()
    results = {
        "분류": "패치관리",
        "코드": "W-54",
        "위험도": "상",
        "진단 항목": "예약된 작업에 의심스러운 명령이 등록되어 있는지 점검",
        "진단 결과": "양호",
        "현황": [],
        "대응방안": "예약된 작업에 의심스러운 명령이 등록되어 있는지 점검"
    }

    if tasks:
        results["진단 결과"] = "경고"
        results["현황"].append("스케줄러에 예약된 작업이 있으며, 이는 승인되지 않은 작업일 수 있습니다.")
    else:
        results["현황"].append("스케줄러에 예약된 작업이 없으며, 이는 보안 상태가 안전함을 나타냅니다.")
    
    # Save the results to a JSON file
    json_path = os.path.join(result_dir, f"W-54_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as file:
        json.dump(results, file, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
