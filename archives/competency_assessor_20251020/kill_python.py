import subprocess
import sys

# Get all Python processes
result = subprocess.run(['tasklist', '/FI', 'IMAGENAME eq python.exe'], capture_output=True, text=True)
print(result.stdout)

# Kill all Python processes
for line in result.stdout.split('\n'):
    if 'python.exe' in line:
        parts = line.split()
        if len(parts) > 1:
            pid = parts[1]
            print(f"Killing PID {pid}...")
            subprocess.run(['taskkill', '/F', '/PID', pid], capture_output=True)

print("All Python processes killed")
