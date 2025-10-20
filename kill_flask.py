import os
import psutil

current_pid = os.getpid()
killed_count = 0

for proc in psutil.process_iter(['pid', 'name']):
    try:
        if 'python' in proc.info['name'].lower() and proc.info['pid'] != current_pid:
            proc.kill()
            print(f"Killed process {proc.info['pid']}")
            killed_count += 1
    except (psutil.NoSuchProcess, psutil.AccessDenied):
        pass

print(f"Total processes killed: {killed_count}")
