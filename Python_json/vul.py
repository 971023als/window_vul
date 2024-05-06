import subprocess
import os
from datetime import datetime
import json
import csv
from pathlib import Path
import sched
import time
import openpyxl

class SecurityDiagnostic:
    def __init__(self, category, code, risk_level, item, result='양호', status=None, response=None):
        self.category = category
        self.code = code
        self.risk_level = risk_level
        self.item = item
        self.result = result
        self.status = status if status else []
        self.response = response

    def update_status(self, new_status):
        self.status.append(new_status)
        print(f"Updated status for {self.code}: {new_status}")

    def update_result(self, new_result):
        self.result = new_result
        print(f"Updated result for {self.code}: {new_result}")

    def display_info(self):
        print(f"분류: {self.category}, 코드: {self.code}, 위험도: {self.risk_level}, 진단항목: {self.item}, 진단결과: {self.result}, 현황: {self.status}, 대응방안: {self.response}")

# 초기 설정
web_directory = "C:\\Users\\User\\Documents"
now = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
results_path = os.path.join(web_directory, f'results_{now}.json')
errors_path = os.path.join(web_directory, f'errors_{now}.log')
csv_path = os.path.join(web_directory, f'results_{now}.csv')

# 스케줄러 설정
scheduler = sched.scheduler(time.time, time.sleep)

def read_diagnostic_data(file_path):
    wb = openpyxl.load_workbook(file_path)
    ws = wb.active
    diagnostics = []
    start_row = 8
    for row in ws.iter_rows(min_row=start_row, min_col=1, max_col=6, values_only=True):
        if row[0] is not None:
            area = row[0]
        if row[3] is not None:
            diagnostic = SecurityDiagnostic(
                category=area,
                code=row[3],
                risk_level=row[1],
                item=row[2],
                result=row[5]
            )
            diagnostics.append(diagnostic)
    return diagnostics

def setup_scheduler():
    def run_script():
        print("스케줄된 작업 실행")
        execute_security_checks()
    scheduler.enter(86400, 1, run_script)
    scheduler.run()

def execute_security_checks():
    print("보안 점검 스크립트 실행")
    errors = []
    diagnostics = read_diagnostic_data('path_to_your_excel_file.xlsx')
    results = []
    for diagnostic in diagnostics:
        script_path = diagnostic.code + '.py'
        if os.path.exists(script_path):
            try:
                result = subprocess.run(['python', script_path], capture_output=True, text=True)
                diagnostic.update_result(result.stdout)
            except Exception as e:
                errors.append(f"{diagnostic.code}: {str(e)}")
        results.append(diagnostic)

    with open(results_path, 'w') as f:
        json.dump([diag.__dict__ for diag in diagnostics], f)
    with open(errors_path, 'w') as f:
        f.writelines(errors)

    with open(csv_path, mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['Area', 'Item', 'Code', 'Status', 'Result', 'Output'])
        for diagnostic in results:
            writer.writerow([diagnostic.category, diagnostic.item, diagnostic.code, diagnostic.risk_level, diagnostic.result, diagnostic.status])

if __name__ == "__main__":
    setup_scheduler()
