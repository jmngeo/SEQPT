"""
Test if the LLM properly maps tasks to involvement levels based on their category.

This test checks whether tasks in "Responsible For" are mapped to "Responsible",
tasks in "Supporting" are mapped to "Supporting", and tasks in "Designing" are
mapped to "Designing".
"""

import os
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app.services.llm_pipeline import llm_process_identification_pipeline as pipeline

# Create a very clear test case
test_tasks = {
    "responsible_for": [
        "Writing C++ code for embedded systems",
        "Implementing software modules according to specifications",
        "Unit testing software components"
    ],
    "supporting": [
        "Code reviews for junior developers",
        "Helping with integration testing"
    ],
    "designing": [
        "Software architecture design for control modules",
        "Defining coding standards and best practices"
    ]
}

print("=" * 80)
print("TESTING INVOLVEMENT LEVEL MAPPING")
print("=" * 80)

print("\n--- INPUT TASKS ---\n")
print("RESPONSIBLE FOR:")
for task in test_tasks["responsible_for"]:
    print(f"  - {task}")

print("\nSUPPORTING:")
for task in test_tasks["supporting"]:
    print(f"  - {task}")

print("\nDESIGNING:")
for task in test_tasks["designing"]:
    print(f"  - {task}")

print("\n" + "=" * 80)
print("RUNNING LLM PIPELINE...")
print("=" * 80)

# Run the pipeline
pipe = pipeline.create_pipeline()
result = pipe(test_tasks)

print("\n--- LLM RESULT ---\n")
print(result)

print("\n" + "=" * 80)
print("ANALYSIS")
print("=" * 80)

# Extract processes from result structure
processes = None
if 'result' in result and hasattr(result['result'], 'processes'):
    processes = result['result'].processes
elif 'processes' in result:
    processes = result['processes']

if processes:

    # Count involvement levels
    involvement_counts = {
        'Responsible': 0,
        'Supporting': 0,
        'Designing': 0,
        'Not performing': 0
    }

    print("\nProcess involvement breakdown:")
    for process in processes:
        # Handle both dict and object attribute access
        if hasattr(process, 'involvement'):
            involvement = process.involvement
            process_name = process.process_name
        else:
            involvement = process.get('involvement', 'Unknown')
            process_name = process.get('process_name', 'Unknown')

        involvement_counts[involvement] = involvement_counts.get(involvement, 0) + 1
        print(f"  {process_name}: {involvement}")

    print("\n--- INVOLVEMENT DISTRIBUTION ---")
    for level, count in involvement_counts.items():
        print(f"  {level}: {count} processes")

    # Check if the LLM is using all three levels
    print("\n--- VERDICT ---")
    if involvement_counts['Responsible'] == 0:
        print("[WARNING] No processes marked as 'Responsible'!")
        print("  This suggests the LLM may not be distinguishing 'Responsible For' tasks.")

    if involvement_counts['Supporting'] == 0:
        print("[WARNING] No processes marked as 'Supporting'!")
        print("  This suggests the LLM may not be distinguishing 'Supporting' tasks.")

    if involvement_counts['Designing'] == 0:
        print("[WARNING] No processes marked as 'Designing'!")
        print("  This suggests the LLM may not be distinguishing 'Designing' tasks.")

    if involvement_counts['Responsible'] > 0 and involvement_counts['Supporting'] > 0 and involvement_counts['Designing'] > 0:
        print("[SUCCESS] All three involvement levels are being used!")
        print("  The LLM is correctly mapping tasks to involvement levels.")
    else:
        print("\n[POTENTIAL ISSUE] The LLM may not be correctly mapping task categories")
        print("to involvement levels. It might be determining involvement purely based on")
        print("the semantic content of the tasks, not based on which section they appear in.")
        print("\nThis could explain why all roles look similar - the involvement levels")
        print("might not be correctly reflecting the user's input structure!")

else:
    print("[ERROR] No processes found in result!")
    print("Result structure:", result)

print("\n" + "=" * 80)
