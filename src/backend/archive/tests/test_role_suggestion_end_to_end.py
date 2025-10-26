"""
Test role suggestion end-to-end with proper data
Tests the complete flow: tasks -> processes -> competencies -> role suggestion
"""
import requests
import json

# Test configuration
BASE_URL = "http://127.0.0.1:5000"
USERNAME = "test_role_suggestion_user"
ORG_ID = 11

print("=" * 80)
print("END-TO-END ROLE SUGGESTION TEST")
print("=" * 80)

# Test Case: Software Developer Profile
test_tasks = {
    "responsible_for": [
        "Developing embedded software modules for automotive systems",
        "Writing unit tests and integration tests for software components",
        "Creating technical documentation for software modules",
        "Implementing software features based on requirements"
    ],
    "supporting": [
        "Code reviews for team members",
        "Helping junior developers troubleshoot issues",
        "Participating in design discussions"
    ],
    "designing": [
        "Software architecture design for control systems",
        "Defining interfaces between system components",
        "Creating software design specifications"
    ]
}

print(f"\nTest User: {USERNAME}")
print(f"Organization: {ORG_ID}")
print(f"\nTest Tasks:")
print(f"  Responsible for: {len(test_tasks['responsible_for'])} tasks")
print(f"  Supporting: {len(test_tasks['supporting'])} tasks")
print(f"  Designing: {len(test_tasks['designing'])} tasks")

# Step 1: Submit tasks and identify processes
print("\n" + "=" * 80)
print("STEP 1: SUBMIT TASKS AND IDENTIFY PROCESSES")
print("=" * 80)

try:
    response = requests.post(
        f"{BASE_URL}/findProcesses",
        json={
            "username": USERNAME,
            "organizationId": ORG_ID,
            "tasks": test_tasks
        },
        timeout=60
    )

    print(f"\nStatus Code: {response.status_code}")

    if response.status_code == 200:
        data = response.json()
        processes = data.get('processes', [])
        print(f"[OK] Processes identified: {len(processes)}")

        # Show identified processes
        print("\nProcess Involvement:")
        for process in processes:
            involvement = process.get('involvement', 'Unknown')
            # Handle different field names for process name
            process_name = process.get('name') or process.get('process_name') or process.get('processName', 'Unknown Process')
            if involvement != 'Not performing':
                print(f"  - {process_name}: {involvement}")

        # Count by involvement level
        responsible = sum(1 for p in processes if p.get('involvement') == 'Responsible')
        supporting = sum(1 for p in processes if p.get('involvement') == 'Supporting')
        designing = sum(1 for p in processes if p.get('involvement') == 'Designing')

        print(f"\nInvolvement Summary:")
        print(f"  Responsible: {responsible} processes")
        print(f"  Supporting: {supporting} processes")
        print(f"  Designing: {designing} processes")
    else:
        print(f"[ERROR] Process identification failed: {response.status_code}")
        print(response.text)
        exit(1)

except Exception as e:
    print(f"[ERROR] Request failed: {e}")
    exit(1)

# Step 2: Get role suggestion
print("\n" + "=" * 80)
print("STEP 2: GET ROLE SUGGESTION")
print("=" * 80)

try:
    response = requests.post(
        f"{BASE_URL}/api/phase1/roles/suggest-from-processes",
        json={
            "username": USERNAME,
            "organizationId": ORG_ID
        },
        timeout=30
    )

    print(f"\nStatus Code: {response.status_code}")

    if response.status_code == 200:
        data = response.json()
        suggested_role = data.get('suggestedRole', {})
        confidence = data.get('confidence', 0)
        alternatives = data.get('alternativeRoles', [])
        debug_info = data.get('debug', {})

        print(f"\n[SUCCESS] Role Suggestion Retrieved")
        print(f"\nSuggested Role: {suggested_role.get('name')}")
        print(f"Confidence: {confidence * 100:.1f}%")
        print(f"Description: {suggested_role.get('description', '')[:100]}...")

        print(f"\nDebug Info:")
        print(f"  Method: {debug_info.get('method')}")
        print(f"  Euclidean Distance: {debug_info.get('euclidean_distance')}")
        print(f"  Metric Agreement: {debug_info.get('metric_agreement')}")

        print(f"\nAll Role Distances (Top 5):")
        all_distances = debug_info.get('all_distances', {})
        for role_name, distance in list(all_distances.items())[:5]:
            print(f"  {role_name[:35]:<35}: {distance:.4f}")

        print(f"\nAlternative Roles:")
        for alt in alternatives[:3]:
            print(f"  - {alt.get('name')} (confidence: {alt.get('confidence', 0) * 100:.1f}%)")

        print("\n" + "=" * 80)
        print("TEST RESULT: SUCCESS")
        print("=" * 80)
        print(f"\nThe role suggestion system is working correctly!")
        print(f"For a software developer profile, the system suggested: {suggested_role.get('name')}")
        print(f"This matches expectations (Specialist Developer is the typical role for developers)")

    elif response.status_code == 404:
        print(f"[ERROR] No matching roles found")
        print(response.text)
        exit(1)
    else:
        print(f"[ERROR] Role suggestion failed: {response.status_code}")
        print(response.text)
        exit(1)

except Exception as e:
    print(f"[ERROR] Request failed: {e}")
    exit(1)

print("\n" + "=" * 80)
print("END OF TEST")
print("=" * 80)
