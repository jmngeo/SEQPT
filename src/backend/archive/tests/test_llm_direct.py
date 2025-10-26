"""
Test the LLM pipeline directly to see what it's returning
"""
import os
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app.services.llm_pipeline import llm_process_identification_pipeline

# Test tasks (same as in test_role_suggestion_end_to_end.py)
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

print("=" * 80)
print("TESTING LLM PIPELINE DIRECTLY")
print("=" * 80)

print("\nCreating pipeline...")
import sys
import io

# Redirect stdout temporarily to suppress verbose output
old_stdout = sys.stdout
sys.stdout = io.StringIO()

pipeline = llm_process_identification_pipeline.create_pipeline()
result = pipeline(test_tasks)

# Restore stdout
sys.stdout = old_stdout

print("\n[Pipeline execution completed]")

print("\n" + "=" * 80)
print("RESULT:")
print("=" * 80)

if result.get("status") == "success":
    llm_result = result.get("result")
    processes = llm_result.processes if hasattr(llm_result, 'processes') else []

    print(f"\nTotal processes returned: {len(processes)}")

    # Count by involvement level
    not_performing = sum(1 for p in processes if p.involvement == 'Not performing')
    supporting = sum(1 for p in processes if p.involvement == 'Supporting')
    responsible = sum(1 for p in processes if p.involvement == 'Responsible')
    designing = sum(1 for p in processes if p.involvement == 'Designing')

    print(f"\nInvolvement counts:")
    print(f"  Not performing: {not_performing}")
    print(f"  Supporting: {supporting}")
    print(f"  Responsible: {responsible}")
    print(f"  Designing: {designing}")

    # Show all processes with non-zero involvement
    print(f"\n{'PROCESSES WITH INVOLVEMENT:':-^80}")
    for process in processes:
        if process.involvement != 'Not performing':
            print(f"  {process.process_name:<60} {process.involvement}")

    # Show first 10 "Not performing" processes
    print(f"\n{'FIRST 10 NOT PERFORMING PROCESSES:':-^80}")
    not_perf_count = 0
    for process in processes:
        if process.involvement == 'Not performing':
            print(f"  {process.process_name}")
            not_perf_count += 1
            if not_perf_count >= 10:
                break
else:
    print(f"[ERROR] Pipeline failed:")
    print(result)

print("\n" + "=" * 80)
print("END OF TEST")
print("=" * 80)
