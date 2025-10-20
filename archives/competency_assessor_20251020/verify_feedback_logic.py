"""
Verify feedback logic for all competency levels.
This script simulates the scenario detection for different level combinations.
"""

# Map BOTH German text levels AND numeric string levels to numeric values
level_map = {
    # German text levels (legacy support)
    'unwissend': 0,
    'kennen': 1,
    'verstehen': 2,
    'anwenden': 4,
    'beherrschen': 6,
    # Numeric string levels (current database format)
    '0': 0,
    '1': 1,
    '2': 2,
    '3': 4,  # Maps to "Applying" (4)
    '4': 6   # Maps to "Mastering" (6)
}

def test_scenario(user_level_str, required_level_str, description):
    """Test scenario detection for a given user and required level"""
    user_level_num = level_map.get(user_level_str.lower(), 0)
    required_level_num = level_map.get(required_level_str.lower(), 0)

    # Determine scenario
    if user_level_num < required_level_num:
        scenario = "BELOW REQUIRED (Scenario 1)"
        expected_feedback = "Improvement suggestions needed"
    elif user_level_num == required_level_num:
        scenario = "MEETS REQUIRED (Scenario 2)"
        expected_feedback = "Celebration + N/A for improvements"
    else:
        scenario = "EXCEEDS REQUIRED (Scenario 3)"
        expected_feedback = "Strong celebration + N/A for improvements"

    print(f"\n{description}")
    print(f"  User Level: {user_level_str} -> {user_level_num}")
    print(f"  Required Level: {required_level_str} -> {required_level_num}")
    print(f"  Scenario: {scenario}")
    print(f"  Expected Feedback: {expected_feedback}")

    return scenario

print("="*80)
print("FEEDBACK LOGIC VERIFICATION - ALL COMPETENCY LEVELS")
print("="*80)

# Test all level combinations
print("\n--- TEST 1: Not Familiar (Level 0) vs Various Required Levels ---")
test_scenario('0', '1', "Not familiar vs Aware (BELOW)")
test_scenario('0', '2', "Not familiar vs Understanding (BELOW)")
test_scenario('0', '3', "Not familiar vs Applying (BELOW)")
test_scenario('0', '4', "Not familiar vs Mastering (BELOW)")

print("\n--- TEST 2: Aware (Level 1) vs Various Required Levels ---")
test_scenario('1', '1', "Aware vs Aware (MEETS)")
test_scenario('1', '2', "Aware vs Understanding (BELOW)")
test_scenario('1', '3', "Aware vs Applying (BELOW)")
test_scenario('1', '4', "Aware vs Mastering (BELOW)")

print("\n--- TEST 3: Understanding (Level 2) vs Various Required Levels ---")
test_scenario('2', '1', "Understanding vs Aware (EXCEEDS)")
test_scenario('2', '2', "Understanding vs Understanding (MEETS)")
test_scenario('2', '3', "Understanding vs Applying (BELOW)")
test_scenario('2', '4', "Understanding vs Mastering (BELOW)")

print("\n--- TEST 4: Applying (Level 3->4) vs Various Required Levels ---")
test_scenario('3', '1', "Applying vs Aware (EXCEEDS)")
test_scenario('3', '2', "Applying vs Understanding (EXCEEDS)")
test_scenario('3', '3', "Applying vs Applying (MEETS)")
test_scenario('3', '4', "Applying vs Mastering (BELOW)")

print("\n--- TEST 5: Mastering (Level 4->6) vs Various Required Levels ---")
test_scenario('4', '1', "Mastering vs Aware (EXCEEDS)")
test_scenario('4', '2', "Mastering vs Understanding (EXCEEDS)")
test_scenario('4', '3', "Mastering vs Applying (EXCEEDS)")
test_scenario('4', '4', "Mastering vs Mastering (MEETS)")

print("\n--- TEST 6: Edge Cases ---")
test_scenario('0', '0', "Not familiar vs Not familiar (MEETS)")

# Test with None values
print("\n--- TEST 7: None/Missing Values ---")
user_level_str = None
required_level_str = '3'
user_level_num = level_map.get((user_level_str or '0').lower(), 0)
required_level_num = level_map.get((required_level_str or '0').lower(), 0)
print(f"\nNone handling test:")
print(f"  User Level: {user_level_str} -> defaults to '0' -> {user_level_num}")
print(f"  Required Level: {required_level_str} -> {required_level_num}")
print(f"  Scenario: {'BELOW REQUIRED' if user_level_num < required_level_num else 'OTHER'}")

print("\n" + "="*80)
print("VERIFICATION COMPLETE")
print("="*80)
print("\nAll scenarios correctly map to:")
print("  - Level 0 (Not familiar) -> 0")
print("  - Level 1 (Aware) -> 1")
print("  - Level 2 (Understanding) -> 2")
print("  - Level 3 (Applying) -> 4")
print("  - Level 4 (Mastering) -> 6")
print("\nScenario detection logic:")
print("  - user < required -> BELOW (needs improvement)")
print("  - user = required -> MEETS (celebration + N/A)")
print("  - user > required -> EXCEEDS (strong celebration + N/A)")
