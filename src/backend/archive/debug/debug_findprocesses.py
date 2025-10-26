"""
Debug the /findProcesses endpoint to see what's happening
"""
import requests
import json

BASE_URL = "http://127.0.0.1:5000"

test_tasks = {
    "responsible_for": [
        "Developing embedded software modules for automotive systems"
    ],
    "supporting": [
        "Code reviews for team members"
    ],
    "designing": [
        "Software architecture design for control systems"
    ]
}

print("=" * 80)
print("DEBUGGING /findProcesses ENDPOINT")
print("=" * 80)

response = requests.post(
    f"{BASE_URL}/findProcesses",
    json={
        "username": "debug_test_user",
        "organizationId": 11,
        "tasks": test_tasks
    },
    timeout=120
)

print(f"\nStatus Code: {response.status_code}")
print(f"\nResponse Headers:")
for key, value in response.headers.items():
    print(f"  {key}: {value}")

print(f"\nResponse Body:")
print(json.dumps(response.json(), indent=2))

print("\n" + "=" * 80)
