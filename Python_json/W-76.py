
import json
import os
import subprocess
import win32security
import win32api
import ntsecuritycon as con
import win32con

def is_admin():
    """ Check if the current user is an administrator. """
    try:
        return os.getuid() == 0
    except AttributeError:
        return win32security.IsUserAnAdmin()

def setup_environment(computer_name):
    """ Setup directories for data storage and return paths. """
    raw_dir = f"C:\\Window_{computer_name}_raw"
    result_dir = f"C:\\Window_{computer_name}_result"
    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(result_dir, exist_ok=True)
    return raw_dir, result_dir

def get_acl_info(path):
    """ Retrieve ACL information for a directory. """
    sd = win32security.GetFileSecurity(path, win32security.DACL_SECURITY_INFORMATION)
    dacl = sd.GetSecurityDescriptorDacl()
    permissions = []
    if dacl:
        for i in range(dacl.GetAceCount()):
            ace = dacl.GetAce(i)
            access_mask, ace_type, ace_flags = ace[1], ace[0][0], ace[0][1]
            if access_mask & con.FILE_ALL_ACCESS:
                user_sid = ace[2]
                user_name, _, _ = win32security.LookupAccountSid(None, user_sid)
                permissions.append(user_name)
    return permissions

def check_directory_permissions(directory):
    """ Check if 'Everyone' has full access to user directories. """
    vulnerable_users = []
    users = [d for d in os.listdir(directory) if os.path.isdir(os.path.join(directory, d))]
    for user in users:
        user_path = os.path.join(directory, user)
        permissions = get_acl_info(user_path)
        if 'Everyone' in permissions:
            vulnerable_users.append(user)
    return vulnerable_users

def main():
    if not is_admin():
        print("관리자 권한으로 스크립트를 실행해야 합니다.")
        return

    computer_name = os.getenv("COMPUTERNAME", "UNKNOWN_PC")
    raw_dir, result_dir = setup_environment(computer_name)
    users_dir = "C:\\Users"

    vulnerable_users = check_directory_permissions(users_dir)

    result = {
        "분류": "보안관리",
        "코드": "W-76",
        "위험도": "상",
        "진단 항목": "사용자별 홈 디렉터리 권한 설정",
        "진단 결과": "양호",  # 기본 값을 "양호"로 가정
        "현황": [],
        "대응방안": "사용자별 홈 디렉터리 권한 설정"
    }

    json_path = os.path.join(result_dir, f"W-74_{computer_name}_diagnostic_results.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, indent=4)

    print(f"진단 결과가 저장되었습니다: {json_path}")

if __name__ == "__main__":
    main()
