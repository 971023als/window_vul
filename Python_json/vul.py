import subprocess
import os
from datetime import datetime
import json
import csv
from pathlib import Path
import sched
import time

# 초기 설정
web_directory = "C:\Users\User\Documents"
now = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
results_path = os.path.join(web_directory, f'results_{now}.json')
errors_path = os.path.join(web_directory, f'errors_{now}.log')
csv_path = os.path.join(web_directory, f'results_{now}.csv')
html_path = os.path.join(web_directory, 'index.html')

# 스케줄러 설정
scheduler = sched.scheduler(time.time, time.sleep)

def setup_scheduler():
    def run_script():
        print("스케줄된 작업 실행")
        # 여기에 보안 점검 스크립트를 실행하는 코드를 추가할 수 있습니다.
    scheduler.enter(86400, 1, run_script)  # 매일 실행
    scheduler.run()

def execute_security_checks():
    print("보안 점검 스크립트 실행")
    errors = []
    results = []
    # 예시: 간단한 Python 스크립트를 실행하는 부분
    for i in range(1, 73):
        script_path = f'W-{i:02}.py'
        if os.path.exists(script_path):
            try:
                result = subprocess.run(['python', script_path], capture_output=True, text=True)
                results.append(result.stdout)
            except Exception as e:
                errors.append(str(e))
    with open(results_path, 'w') as f:
        json.dump(results, f)
    with open(errors_path, 'w') as f:
        f.writelines(errors)

def convert_results():
    print("결과 변환")
    with open(results_path, 'r') as json_file, \
         open(csv_path, 'w', newline='', encoding='utf-8-sig') as csv_file, \
         open(html_path, 'w', encoding='utf-8') as html_file:
        data = json.load(json_file)
        if data:
            writer = csv.DictWriter(csv_file, fieldnames=data[0].keys())
            writer.writeheader()
            writer.writerows(data)
            html_file.write('<!DOCTYPE html><html><head><title>Security Check Results</title></head><body>')
            html_file.write('<h1>Security Check Results</h1>')
            html_file.write('<table>')
            headers = data[0].keys()
            html_file.write('<tr>' + ''.join(f'<th>{h}</th>' for h in headers) + '</tr>')
            for item in data:
                row = '<tr>' + ''.join(f'<td>{item[h]}</td>' for h in headers) + '</tr>'
                html_file.write(row)
            html_file.write('</table></body></html>')

def main():
    # setup_scheduler()  # 크론 작업을 스케줄러로 설정
    execute_security_checks()
    convert_results()

if __name__ == "__main__":
    main()
