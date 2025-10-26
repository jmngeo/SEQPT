"""
Check database values for debug_test_user
"""
from models import UnknownRoleProcessMatrix, IsoProcesses, db
from app import create_app

app = create_app()

with app.app_context():
    results = UnknownRoleProcessMatrix.query.filter_by(
        user_name='debug_test_user',
        organization_id=11
    ).all()

    print(f"Total processes for debug_test_user: {len(results)}")

    non_zero = [r for r in results if r.role_process_value > 0]
    print(f"Non-zero values: {len(non_zero)}")

    print("\nNon-zero processes:")
    for result in non_zero:
        process = IsoProcesses.query.filter_by(id=result.iso_process_id).first()
        process_name = process.name if process else "Unknown"
        print(f"  Process ID {result.iso_process_id} ({process_name}): value={result.role_process_value}")

    if len(non_zero) == 0:
        print("  (None found - all values are 0)")

    # Distribution
    from collections import Counter
    distribution = Counter([r.role_process_value for r in results])
    print("\nValue distribution:")
    for value in sorted(distribution.keys()):
        print(f"  Value {value}: {distribution[value]} processes")

    # Show sample of processes with value 0
    if len(non_zero) < len(results):
        print("\nSample of processes with value 0 (first 3):")
        zeros = [r for r in results if r.role_process_value == 0][:3]
        for result in zeros:
            process = IsoProcesses.query.filter_by(id=result.iso_process_id).first()
            process_name = process.name if process else "Unknown"
            print(f"  Process ID {result.iso_process_id} ({process_name}): value={result.role_process_value}")
