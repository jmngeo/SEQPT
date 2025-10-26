"""
Comprehensive End-to-End Test for Task-Based Role Mapping
Tests the complete workflow:
1. Submit tasks via /findProcesses
2. Verify process involvement values stored in database
3. Get role suggestions via /getRoleSuggestion
4. Validate results
"""

import requests
import psycopg2
import json
from datetime import datetime

# Configuration
BASE_URL = "http://127.0.0.1:5000"
DATABASE_URL = "postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment"
TEST_USERNAME = "e2e_test_user"
ORG_ID = 11

# Test scenarios with different task profiles
TEST_SCENARIOS = [
    {
        "name": "Software Architect",
        "tasks": {
            "responsible_for": [
                "Developing embedded software modules for automotive systems",
                "Writing unit tests and integration tests",
                "Creating technical documentation for software components"
            ],
            "supporting": [
                "Code reviews for team members",
                "Helping junior developers troubleshoot issues",
                "Participating in sprint planning meetings"
            ],
            "designing": [
                "Software architecture design for control systems",
                "Defining interfaces between system components",
                "Creating system design specifications"
            ]
        },
        "expected_processes": ["System Architecture Definition", "Design Definition", "Implementation"]
    },
    {
        "name": "Systems Engineer",
        "tasks": {
            "responsible_for": [
                "Managing system integration activities",
                "Coordinating between hardware and software teams",
                "Tracking system requirements"
            ],
            "supporting": [
                "Assisting with verification testing",
                "Supporting validation activities"
            ],
            "designing": [
                "System architecture planning",
                "Requirements analysis and decomposition"
            ]
        },
        "expected_processes": ["Integration", "System Architecture Definition", "System Requirements Definition"]
    }
]


def print_header(text):
    """Print a formatted header"""
    print("\n" + "="*80)
    print(f"  {text}")
    print("="*80)


def print_section(text):
    """Print a formatted section"""
    print("\n" + "-"*80)
    print(f"  {text}")
    print("-"*80)


def clear_test_user_data():
    """Clear any existing data for the test user"""
    print_section("Clearing existing test user data")
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()

    cur.execute("""
        DELETE FROM unknown_role_process_matrix
        WHERE user_name = %s AND organization_id = %s
    """, (TEST_USERNAME, ORG_ID))

    deleted = cur.rowcount
    conn.commit()
    cur.close()
    conn.close()

    print(f"Deleted {deleted} existing records for user '{TEST_USERNAME}'")


def test_find_processes(scenario):
    """Test Step 1: Submit tasks to /findProcesses endpoint"""
    print_section(f"Testing /findProcesses for: {scenario['name']}")

    payload = {
        "username": TEST_USERNAME,
        "organizationId": ORG_ID,
        "tasks": scenario["tasks"]
    }

    print(f"Submitting tasks:")
    print(f"  Responsible for: {len(scenario['tasks']['responsible_for'])} tasks")
    print(f"  Supporting: {len(scenario['tasks']['supporting'])} tasks")
    print(f"  Designing: {len(scenario['tasks']['designing'])} tasks")

    response = requests.post(
        f"{BASE_URL}/findProcesses",
        json=payload,
        headers={"Content-Type": "application/json"}
    )

    print(f"\nResponse Status: {response.status_code}")

    if response.status_code == 200:
        data = response.json()
        print(f"Response: {data.get('status', 'unknown')}")

        if "processes" in data:
            processes = data["processes"]
            print(f"\nIdentified {len(processes)} processes:")

            # Group by involvement level
            by_involvement = {}
            for proc in processes:
                involvement = proc.get("involvement", "Unknown")
                if involvement not in by_involvement:
                    by_involvement[involvement] = []
                by_involvement[involvement].append(proc.get("process_name", "Unknown"))

            for involvement, proc_list in sorted(by_involvement.items()):
                if involvement != "Not performing":
                    print(f"\n  {involvement}:")
                    for proc in proc_list:
                        print(f"    - {proc}")

            not_performing_count = len(by_involvement.get("Not performing", []))
            if not_performing_count > 0:
                print(f"\n  Not performing: {not_performing_count} processes")

        return True
    else:
        print(f"ERROR: {response.text}")
        return False


def verify_database_storage():
    """Test Step 2: Verify process involvement values in database"""
    print_section("Verifying Database Storage")

    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()

    # Get all process values for test user
    cur.execute("""
        SELECT
            urpm.iso_process_id,
            ip.name,
            urpm.role_process_value,
            CASE urpm.role_process_value
                WHEN 0 THEN 'Not performing'
                WHEN 1 THEN 'Supporting'
                WHEN 2 THEN 'Responsible'
                WHEN 4 THEN 'Designing'
                ELSE 'Unknown'
            END as involvement_level
        FROM unknown_role_process_matrix urpm
        JOIN iso_processes ip ON urpm.iso_process_id = ip.id
        WHERE urpm.user_name = %s
        AND urpm.organization_id = %s
        ORDER BY urpm.role_process_value DESC, ip.name
    """, (TEST_USERNAME, ORG_ID))

    results = cur.fetchall()

    if not results:
        print(f"[WARNING] No data found for user '{TEST_USERNAME}'")
        cur.close()
        conn.close()
        return False

    # Count by involvement level
    counts = {"Not performing": 0, "Supporting": 0, "Responsible": 0, "Designing": 0}
    non_zero_processes = []

    for row in results:
        process_id, process_name, value, involvement = row
        counts[involvement] = counts.get(involvement, 0) + 1
        if value != 0:
            non_zero_processes.append((process_name, involvement, value))

    print(f"\nTotal processes: {len(results)}")
    print(f"\nValue Distribution:")
    print(f"  Designing (4):     {counts.get('Designing', 0)}")
    print(f"  Responsible (2):   {counts.get('Responsible', 0)}")
    print(f"  Supporting (1):    {counts.get('Supporting', 0)}")
    print(f"  Not performing (0): {counts.get('Not performing', 0)}")

    if non_zero_processes:
        print(f"\nNon-zero Process Involvements ({len(non_zero_processes)}):")
        for proc_name, involvement, value in non_zero_processes:
            print(f"  [{value}] {involvement}: {proc_name}")
    else:
        print("\n[WARNING] All process values are 0 (Not performing)")

    cur.close()
    conn.close()

    return len(non_zero_processes) > 0


def test_role_suggestion():
    """Test Step 3: Get role suggestions based on stored data"""
    print_section("Testing Role Suggestion")

    payload = {
        "username": TEST_USERNAME,
        "organizationId": ORG_ID
    }

    response = requests.post(
        f"{BASE_URL}/getRoleSuggestion",
        json=payload,
        headers={"Content-Type": "application/json"}
    )

    print(f"Response Status: {response.status_code}")

    if response.status_code == 200:
        data = response.json()

        if "role_suggestion" in data:
            role_suggestion = data["role_suggestion"]
            print(f"\n[SUCCESS] Role Suggested: {role_suggestion}")

            if "similarity_score" in data:
                print(f"Similarity Score: {data['similarity_score']:.2f}%")

            if "top_matches" in data:
                print(f"\nTop {len(data['top_matches'])} Role Matches:")
                for idx, match in enumerate(data['top_matches'], 1):
                    role_name = match.get('role_name', 'Unknown')
                    score = match.get('similarity_score', 0)
                    print(f"  {idx}. {role_name}: {score:.2f}%")

            return True
        else:
            print(f"\n[WARNING] No role suggestion in response")
            print(f"Response: {json.dumps(data, indent=2)}")
            return False
    else:
        print(f"ERROR: {response.text}")
        return False


def run_comprehensive_test():
    """Run the complete end-to-end test"""
    print_header("COMPREHENSIVE END-TO-END TASK-BASED ROLE MAPPING TEST")
    print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Test User: {TEST_USERNAME}")
    print(f"Organization ID: {ORG_ID}")

    # Test each scenario
    for scenario in TEST_SCENARIOS:
        print_header(f"SCENARIO: {scenario['name']}")

        # Step 0: Clear existing data
        clear_test_user_data()

        # Step 1: Submit tasks
        step1_success = test_find_processes(scenario)
        if not step1_success:
            print(f"\n[FAILED] Step 1 failed for scenario: {scenario['name']}")
            continue

        # Step 2: Verify database storage
        step2_success = verify_database_storage()
        if not step2_success:
            print(f"\n[FAILED] Step 2 failed - no data stored in database")
            continue

        # Step 3: Get role suggestion
        step3_success = test_role_suggestion()
        if not step3_success:
            print(f"\n[FAILED] Step 3 failed - role suggestion not working")
            continue

        print(f"\n[SUCCESS] All steps completed for scenario: {scenario['name']}")

    print_header("TEST SUMMARY")
    print(f"Tested {len(TEST_SCENARIOS)} scenarios")
    print(f"Test completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")


if __name__ == "__main__":
    run_comprehensive_test()
