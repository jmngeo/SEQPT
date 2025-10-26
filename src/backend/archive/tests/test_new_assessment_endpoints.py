"""
Test script for the new assessment endpoints
Tests all 4 new endpoints:
1. POST /assessment/start
2. POST /assessment/<id>/submit
3. GET /assessment/<id>/results
4. GET /user/<id>/assessments
"""

import requests
import json

BASE_URL = "http://localhost:5000"

def print_section(title):
    print("\n" + "="*60)
    print(f"  {title}")
    print("="*60)

def test_endpoint_1_start_assessment():
    """Test POST /assessment/start"""
    print_section("TEST 1: POST /assessment/start")

    # First, login to get a token
    login_data = {
        "username": "test_user",
        "password": "testpass123"
    }

    print(f"\n[STEP 1] Logging in as admin...")
    login_response = requests.post(f"{BASE_URL}/mvp/auth/login", json=login_data)
    print(f"Status: {login_response.status_code}")

    if login_response.status_code != 200:
        print(f"[ERROR] Login failed: {login_response.text}")
        return None, None

    login_result = login_response.json()
    token = login_result.get('access_token')
    user_id = login_result.get('user', {}).get('id')

    print(f"[SUCCESS] Logged in. User ID: {user_id}, Token: {token[:20]}...")

    # Now start an assessment
    print(f"\n[STEP 2] Starting a new assessment...")
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {token}"
    }

    assessment_data = {
        "user_id": user_id,
        "organization_id": 1,
        "assessment_type": "task_based"
    }

    response = requests.post(f"{BASE_URL}/assessment/start", json=assessment_data, headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")

    if response.status_code == 201:
        result = response.json()
        assessment_id = result.get('assessment_id')
        print(f"\n[SUCCESS] Assessment created! ID: {assessment_id}")
        return assessment_id, token
    else:
        print(f"\n[ERROR] Failed to create assessment")
        return None, token

def test_endpoint_2_submit_assessment(assessment_id, token):
    """Test POST /assessment/<id>/submit"""
    if not assessment_id:
        print("\n[SKIP] No assessment_id, skipping submit test")
        return False

    print_section(f"TEST 2: POST /assessment/{assessment_id}/submit")

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {token}"
    }

    # Minimal test data - just to test the endpoint works
    submit_data = {
        "competency_scores": [
            {"competency_id": 1, "user_score": 3, "max_score": 5},
            {"competency_id": 4, "user_score": 4, "max_score": 5}
        ],
        "selected_roles": [{"role_id": 1, "role_name": "Software Developer"}],
        "tasks_json": {
            "responsible_for": ["Coding"],
            "supporting": ["Testing"],
            "designing": ["Architecture"]
        }
    }

    print(f"\n[STEP 1] Submitting assessment data...")
    response = requests.post(f"{BASE_URL}/assessment/{assessment_id}/submit", json=submit_data, headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")

    if response.status_code == 200:
        print(f"\n[SUCCESS] Assessment submitted!")
        return True
    else:
        print(f"\n[ERROR] Failed to submit assessment")
        return False

def test_endpoint_3_get_results(assessment_id, token):
    """Test GET /assessment/<id>/results"""
    if not assessment_id:
        print("\n[SKIP] No assessment_id, skipping results test")
        return

    print_section(f"TEST 3: GET /assessment/{assessment_id}/results")

    headers = {
        "Authorization": f"Bearer {token}"
    }

    print(f"\n[STEP 1] Fetching assessment results...")
    response = requests.get(f"{BASE_URL}/assessment/{assessment_id}/results", headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")

    if response.status_code == 200:
        print(f"\n[SUCCESS] Results retrieved!")
    else:
        print(f"\n[ERROR] Failed to get results")

def test_endpoint_4_get_user_assessments(user_id, token):
    """Test GET /user/<id>/assessments"""
    if not user_id:
        print("\n[SKIP] No user_id, skipping history test")
        return

    print_section(f"TEST 4: GET /user/{user_id}/assessments")

    headers = {
        "Authorization": f"Bearer {token}"
    }

    print(f"\n[STEP 1] Fetching user assessment history...")
    response = requests.get(f"{BASE_URL}/user/{user_id}/assessments", headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")

    if response.status_code == 200:
        result = response.json()
        count = len(result.get('assessments', []))
        print(f"\n[SUCCESS] Found {count} assessments in history!")
    else:
        print(f"\n[ERROR] Failed to get assessment history")

def main():
    print("\n" + "="*60)
    print("  TESTING NEW ASSESSMENT ENDPOINTS")
    print("="*60)
    print("\nThis will test all 4 new endpoints in sequence:")
    print("1. POST /assessment/start")
    print("2. POST /assessment/<id>/submit")
    print("3. GET /assessment/<id>/results")
    print("4. GET /user/<id>/assessments")
    print("\n" + "="*60)

    # Test 1: Start assessment
    assessment_id, token = test_endpoint_1_start_assessment()

    if not assessment_id:
        print("\n[FATAL] Could not create assessment. Stopping tests.")
        return

    # Test 2: Submit assessment
    submitted = test_endpoint_2_submit_assessment(assessment_id, token)

    # Test 3: Get results (works even if submit failed)
    test_endpoint_3_get_results(assessment_id, token)

    # Test 4: Get user assessment history
    # Extract user_id from token by logging in again
    login_response = requests.post(f"{BASE_URL}/mvp/auth/login", json={"username": "test_user", "password": "testpass123"})
    if login_response.status_code == 200:
        user_id = login_response.json().get('user', {}).get('id')
        test_endpoint_4_get_user_assessments(user_id, token)

    print_section("ALL TESTS COMPLETE")
    print("\nCheck the output above for any [ERROR] messages.")
    print("All endpoints with [SUCCESS] are working correctly.\n")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\n[FATAL ERROR] {str(e)}")
        import traceback
        traceback.print_exc()
