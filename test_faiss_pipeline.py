"""
Test script to verify FAISS-based LLM pipeline for task-based role mapping
"""
import requests
import json

BASE_URL = "http://127.0.0.1:5000"

# Test profile: Software Developer
software_developer_tasks = {
    "username": "test_sw_dev_faiss",
    "organizationId": 11,
    "tasks": {
        "responsible_for": [
            "Developing embedded software modules for automotive control systems",
            "Writing unit tests and integration tests for safety-critical code",
            "Creating technical documentation for software components",
            "Debugging and fixing software defects reported by QA team"
        ],
        "supporting": [
            "Code reviews for team members to ensure quality standards",
            "Helping junior developers troubleshoot technical issues",
            "Collaborating with system architects on interface definitions"
        ],
        "designing": [
            "Software architecture design for control algorithms",
            "Defining interfaces between embedded software modules",
            "Creating UML diagrams for software component interactions"
        ]
    }
}

print("=" * 80)
print("FAISS-BASED PIPELINE TEST - Software Developer Profile")
print("=" * 80)

# Step 1: Call /findProcesses to trigger LLM pipeline with FAISS retrieval
print("\n[STEP 1] Calling /findProcesses endpoint...")
print(f"Username: {software_developer_tasks['username']}")
print(f"Organization: {software_developer_tasks['organizationId']}")

response = requests.post(
    f"{BASE_URL}/findProcesses",
    json=software_developer_tasks,
    headers={"Content-Type": "application/json"}
)

print(f"\nStatus Code: {response.status_code}")

if response.status_code == 200:
    result = response.json()
    print("\n[SUCCESS] Process identification completed!")

    if "processes" in result:
        processes = result["processes"]
        print(f"\n[PROCESSES IDENTIFIED] {len(processes)} processes:")
        for proc in processes:
            print(f"  - {proc['process_name']}: {proc['involvement']}")
    else:
        print("\n[RESULT]", json.dumps(result, indent=2))

    # Step 2: Verify UnknownRoleProcessMatrix populated
    print("\n" + "=" * 80)
    print("[STEP 2] Verifying database entries...")
    print("=" * 80)

    # Step 3: Call /api/phase1/roles/suggest-from-processes
    print("\n" + "=" * 80)
    print("[STEP 3] Calling role suggestion endpoint...")
    print("=" * 80)

    suggest_payload = {
        "username": software_developer_tasks['username'],
        "organizationId": software_developer_tasks['organizationId']
    }

    suggest_response = requests.post(
        f"{BASE_URL}/api/phase1/roles/suggest-from-processes",
        json=suggest_payload,
        headers={"Content-Type": "application/json"}
    )

    print(f"\nStatus Code: {suggest_response.status_code}")

    if suggest_response.status_code == 200:
        role_result = suggest_response.json()
        print("\n[SUCCESS] Role suggestion completed!")
        print("\n[SUGGESTED ROLE]")
        print(json.dumps(role_result, indent=2))

        # Analyze the result
        if "suggestedRole" in role_result:
            suggested = role_result["suggestedRole"]
            print(f"\n[RESULT ANALYSIS]")
            print(f"Role Name: {suggested.get('name', 'N/A')}")
            print(f"Confidence: {role_result.get('confidence', 'N/A')}")

            # Check if it's the expected role
            expected_roles = ["Specialist Developer", "System Engineer"]
            if suggested.get('name') in expected_roles:
                print("\n[PASS] Got expected role!")
            else:
                print(f"\n[REVIEW NEEDED] Got '{suggested.get('name')}', expected one of: {expected_roles}")
    else:
        print(f"\n[ERROR] {suggest_response.status_code}")
        print(suggest_response.text)
else:
    print(f"\n[ERROR] Process identification failed!")
    print(response.text)

print("\n" + "=" * 80)
print("TEST COMPLETED")
print("=" * 80)
