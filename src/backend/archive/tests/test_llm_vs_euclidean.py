"""
Test and compare LLM-based role selection vs Euclidean distance matching.

This will help determine which approach gives better results for the
role mapping test cases that previously failed.
"""

import requests
import json

# Test backend URL
BASE_URL = "http://localhost:5000"

# Test cases from ROLE_MAPPING_TEST_FAILURE_ANALYSIS.md
test_cases = [
    {
        "name": "Test 1: Senior Software Developer",
        "expected_role": "Specialist Developer",
        "tasks": {
            "responsible_for": [
                "Developing embedded software modules for automotive control systems",
                "Writing unit tests and integration tests for software components",
                "Creating technical documentation for software designs",
                "Implementing software modules according to system specifications",
                "Debugging and fixing software defects"
            ],
            "supporting": [
                "Code reviews for junior developers",
                "Helping team members troubleshoot technical issues",
                "Mentoring junior engineers in software best practices",
                "Supporting integration testing activities"
            ],
            "designing": [
                "Software architecture for control modules",
                "Design patterns and coding standards",
                "Software development processes and workflows",
                "Continuous integration and deployment pipelines"
            ]
        }
    },
    {
        "name": "Test 2: Systems Integration Engineer",
        "expected_role": "System Engineer",
        "tasks": {
            "responsible_for": [
                "Integrating software and hardware components into complete systems",
                "Coordinating interfaces between different system modules",
                "Defining integration test procedures and executing tests",
                "Managing system-level requirements and specifications",
                "Ensuring compatibility across system boundaries"
            ],
            "supporting": [
                "System architecture reviews",
                "Requirements analysis and decomposition",
                "Stakeholder communication and coordination",
                "Risk assessment for integration activities"
            ],
            "designing": [
                "System integration strategies and approaches",
                "Interface specifications between components",
                "Integration testing frameworks",
                "System verification procedures"
            ]
        }
    },
    {
        "name": "Test 3: Quality Assurance Specialist",
        "expected_role": "Quality Engineer/Manager",
        "tasks": {
            "responsible_for": [
                "Developing and executing test plans for software and systems",
                "Identifying and documenting software defects",
                "Ensuring compliance with quality standards and regulations",
                "Performing regression testing on software releases",
                "Managing defect tracking and resolution processes"
            ],
            "supporting": [
                "Process improvement initiatives",
                "Root cause analysis of quality issues",
                "Training team members on testing procedures",
                "Quality metrics collection and reporting"
            ],
            "designing": [
                "Quality assurance processes and procedures",
                "Test automation frameworks",
                "Quality metrics and KPIs",
                "Continuous improvement initiatives"
            ]
        }
    }
]

def test_role_mapping(test_case):
    """Test both approaches for a single test case."""
    print(f"\n{'='*80}")
    print(f"Testing: {test_case['name']}")
    print(f"Expected Role: {test_case['expected_role']}")
    print(f"{'='*80}\n")

    # Generate username
    import time
    import random
    username = f"test_llm_vs_euclidean_{int(time.time())}_{random.randint(1000, 9999)}"

    # Step 1: Call /findProcesses
    print("Step 1: Calling /findProcesses to get process mapping AND LLM role suggestion...")
    find_processes_url = f"{BASE_URL}/findProcesses"
    find_processes_payload = {
        "username": username,
        "organizationId": 11,
        "tasks": test_case["tasks"]
    }

    try:
        response = requests.post(find_processes_url, json=find_processes_payload)
        response.raise_for_status()
        find_processes_result = response.json()

        print(f"  Status: {find_processes_result.get('status')}")
        print(f"  Processes identified: {len(find_processes_result.get('processes', []))}")

        # Check for LLM role suggestion
        llm_suggestion = find_processes_result.get('llm_role_suggestion')
        if llm_suggestion:
            print(f"\n  LLM Role Suggestion:")
            print(f"    Role ID: {llm_suggestion['role_id']}")
            print(f"    Role Name: {llm_suggestion['role_name']}")
            print(f"    Confidence: {llm_suggestion['confidence']}")
            print(f"    Reasoning: {llm_suggestion['reasoning']}")
        else:
            print("\n  [WARNING] No LLM role suggestion in response!")

    except requests.exceptions.RequestException as e:
        print(f"  [ERROR] Failed to call /findProcesses: {e}")
        return None

    # Step 2: Call /api/phase1/roles/suggest-from-processes (Euclidean distance)
    print("\nStep 2: Calling /suggest-from-processes for Euclidean distance matching...")
    suggest_role_url = f"{BASE_URL}/api/phase1/roles/suggest-from-processes"
    suggest_role_payload = {
        "username": username,
        "organizationId": 11
    }

    try:
        response = requests.post(suggest_role_url, json=suggest_role_payload)
        response.raise_for_status()
        euclidean_result = response.json()

        print(f"  Suggested Role: {euclidean_result['suggestedRole']['name']} (ID: {euclidean_result['suggestedRole']['id']})")
        print(f"  Euclidean Distance: {euclidean_result.get('distance', 'N/A')}")
        print(f"  Confidence: {euclidean_result.get('confidence', 'N/A')}%")

    except requests.exceptions.RequestException as e:
        print(f"  [ERROR] Failed to call /suggest-from-processes: {e}")
        euclidean_result = None

    # Compare results
    print(f"\n{'='*80}")
    print("COMPARISON")
    print(f"{'='*80}")
    print(f"Expected Role: {test_case['expected_role']}")

    if llm_suggestion:
        llm_correct = test_case['expected_role'].lower() in llm_suggestion['role_name'].lower()
        print(f"\nLLM Suggestion: {llm_suggestion['role_name']} - {'[CORRECT]' if llm_correct else '[WRONG]'}")
        print(f"  Confidence: {llm_suggestion['confidence']}")
    else:
        print(f"\nLLM Suggestion: NOT AVAILABLE")
        llm_correct = False

    if euclidean_result:
        euclidean_correct = test_case['expected_role'].lower() in euclidean_result['suggestedRole']['name'].lower()
        print(f"\nEuclidean Distance: {euclidean_result['suggestedRole']['name']} - {'[CORRECT]' if euclidean_correct else '[WRONG]'}")
        print(f"  Distance: {euclidean_result.get('distance', 'N/A')}")
        print(f"  Confidence: {euclidean_result.get('confidence', 'N/A')}%")
    else:
        print(f"\nEuclidean Distance: NOT AVAILABLE")
        euclidean_correct = False

    # Winner
    if llm_correct and not euclidean_correct:
        print(f"\n>>> WINNER: LLM approach! <<<")
    elif euclidean_correct and not llm_correct:
        print(f"\n>>> WINNER: Euclidean distance approach! <<<")
    elif llm_correct and euclidean_correct:
        print(f"\n>>> BOTH APPROACHES CORRECT! <<<")
    else:
        print(f"\n>>> BOTH APPROACHES WRONG <<<")

    return {
        "test_name": test_case["name"],
        "expected": test_case["expected_role"],
        "llm_result": llm_suggestion['role_name'] if llm_suggestion else None,
        "llm_correct": llm_correct,
        "euclidean_result": euclidean_result['suggestedRole']['name'] if euclidean_result else None,
        "euclidean_correct": euclidean_correct
    }


if __name__ == "__main__":
    print("=" * 80)
    print("LLM ROLE SELECTION VS EUCLIDEAN DISTANCE COMPARISON")
    print("=" * 80)

    results = []
    for test_case in test_cases:
        result = test_role_mapping(test_case)
        if result:
            results.append(result)

    # Summary
    print(f"\n\n{'='*80}")
    print("SUMMARY")
    print(f"{'='*80}\n")

    llm_correct_count = sum(1 for r in results if r['llm_correct'])
    euclidean_correct_count = sum(1 for r in results if r['euclidean_correct'])

    print(f"LLM Approach: {llm_correct_count}/{len(results)} correct ({100*llm_correct_count/len(results):.0f}%)")
    print(f"Euclidean Distance: {euclidean_correct_count}/{len(results)} correct ({100*euclidean_correct_count/len(results):.0f}%)")

    print(f"\nDetailed Results:")
    for r in results:
        print(f"\n{r['test_name']}:")
        print(f"  Expected: {r['expected']}")
        print(f"  LLM: {r['llm_result']} - {'[OK]' if r['llm_correct'] else '[FAIL]'}")
        print(f"  Euclidean: {r['euclidean_result']} - {'[OK]' if r['euclidean_correct'] else '[FAIL]'}")

    if llm_correct_count > euclidean_correct_count:
        print(f"\n>>> OVERALL WINNER: LLM approach with {llm_correct_count - euclidean_correct_count} more correct predictions! <<<")
    elif euclidean_correct_count > llm_correct_count:
        print(f"\n>>> OVERALL WINNER: Euclidean distance with {euclidean_correct_count - llm_correct_count} more correct predictions! <<<")
    else:
        print(f"\n>>> TIE: Both approaches performed equally! <<<")
