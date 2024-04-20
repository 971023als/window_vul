import os
import json
import subprocess
import winreg

def check_admin():
    """Check if the script is running with administrator privileges."""
    try:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
    except Exception:
        return False

def setup_directories(computer_name):
    """Prepare directories for storing raw data and results."""
    raw_dir = f"C:\\Window_{computer_name}_raw"
    result_dir = f"C:\\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def check_odbc_data_sources():
    """Check for configured ODBC data sources in the registry."""
    try:
        key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources")
        data_sources = []
        i = 0
        while True:
            try:
                data_sources.append(winreg.EnumValue(key, i))
                i += 1
            except OSError:
                break
        winreg.CloseKey(key)
        return True, data_sources if data_sources else False, []
    except FileNotFoundError:
        return False, []

def main():
    if not check_admin():
        print("이 스크립트는 관리자 권한으로 실행되어야 합니다.")
        return
    
    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_directories(computer_name)
    
    has_sources, data_sources = check_odbc_data_sources()
    results = {
        "분류": "서비스관리",
        "코드": "W-52",
        "위험도": "상",
        "진단 항목": "불필요한 ODBC/OLE-DB 데이터 소스와 드라이브 제거",
        "진단 결과": "양호" if not has_sources else "취약",
        "현황": [],
        "대응방안": "HTTP/FTP/SMTP 배너 차단"
    }

    if has_sources:
        results["현황"].append(f"ODBC 데이터 소스가 구성되어 있으며, 이는 필요하지 않을 경우 취약점이 될 수 있습니다: {data_sources}")
    else:
        results["현황"].append("불필요한 ODBC 데이터 소스가 구성되어 있지 않으며, 시스템은 안전합니다.")
    
    # Save the results to a JSON file
    json_path = os.path.join(result_dir, f"W-52_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=4)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
