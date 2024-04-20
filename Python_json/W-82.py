import json
import os
import subprocess
import pyodbc
from pathlib import Path

def check_admin_rights():
    """Check if the script is running with administrative privileges."""
    try:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
    except Exception as e:
        print(f"Error checking admin rights: {e}")
        return False

def get_sql_auth_mode(server_name):
    """Retrieve the authentication mode from SQL Server."""
    try:
        connection_string = f"DRIVER={{SQL Server}};SERVER={server_name};Trusted_Connection=yes;"
        query = "SELECT SERVERPROPERTY('IsIntegratedSecurityOnly')"
        with pyodbc.connect(connection_string, timeout=5) as conn:
            with conn.cursor() as cursor:
                cursor.execute(query)
                result = cursor.fetchone()
                return result[0] if result else None
    except Exception as e:
        print(f"Error connecting to SQL Server: {e}")
        return None

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
    
    # SQL Server 인스턴스 이름 설정
    sql_server_instance = "YourSQLServerInstanceName"
    auth_mode = get_sql_auth_mode(sql_server_instance)
    
    # Define the JSON structure
    security_data = {
        "분류": "보안관리",
        "코드": "W-82",
        "위험도": "상",
        "진단 항목": "Windows 인증 모드 사용",
        "진단 결과": "양호" if auth_mode == 1 else "취약",
        "현황": [f"Windows 인증 모드가 {'활성화되어 있습니다.' if auth_mode == 1 else '비활성화되어 있습니다. 혼합 모드 인증이 사용 중입니다.'}"],
        "대응방안": "Windows 인증 모드 사용"
    }
    
    # Save results to JSON
    json_path = result_dir / f"W-82_{computer_name}_diagnostic_results.json"
    save_results(security_data, json_path)
    
    print(f"진단 결과가 저장되었습니다: {json_path}")
    print("스크립트가 완료되었습니다.")

if __name__ == "__main__":
    main()
