"""
Fix the 11 discrepancies in role_competency_matrix to match Derik's exact values
"""
import os
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app import create_app
from models import db
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("="*80)
    print("FIXING ROLE_COMPETENCY_MATRIX DISCREPANCIES")
    print("="*80)

    # The 11 discrepancies identified:
    # Format: (role_id, comp_id, our_current_value, derik_correct_value)
    discrepancies = [
        (5, 1, 4, 2),
        (5, 7, 4, 2),
        (5, 14, 4, 2),
        (5, 15, 2, 4),
        (5, 17, 0, 1),
        (9, 1, 2, 4),
        (9, 10, 1, 4),
        (9, 14, 2, 4),
        (9, 15, 4, 2),
        (10, 14, 1, 2),
        (10, 17, 2, 4),
    ]

    role_names = {
        5: "Specialist Developer",
        9: "Verification and Validation (V&V) Operator",
        10: "Service Technician"
    }

    print(f"\nFound {len(discrepancies)} discrepancies to fix:\n")

    for role_id, comp_id, our_val, derik_val in discrepancies:
        role_name = role_names.get(role_id, f"Role {role_id}")
        print(f"  {role_name} (Role {role_id}), Competency {comp_id:2d}: {our_val} -> {derik_val}")

    print("\n" + "-"*80)
    proceed = input("\nProceed with fixing these values? (yes/no): ")

    if proceed.lower() != 'yes':
        print("Aborted.")
        exit()

    print("\nApplying fixes...")
    fixed_count = 0

    for role_id, comp_id, our_val, derik_val in discrepancies:
        # Update the value
        result = db.session.execute(text("""
            UPDATE role_competency_matrix
            SET role_competency_value = :new_value
            WHERE role_cluster_id = :role_id
              AND competency_id = :comp_id
              AND organization_id = 1
        """), {
            "new_value": derik_val,
            "role_id": role_id,
            "comp_id": comp_id
        })

        if result.rowcount > 0:
            fixed_count += 1
            print(f"  [OK] Role {role_id}, Comp {comp_id}: {our_val} -> {derik_val}")
        else:
            print(f"  [ERROR] Role {role_id}, Comp {comp_id}: NOT FOUND")

    db.session.commit()

    print("\n" + "="*80)
    print(f"FIXES APPLIED: {fixed_count}/{len(discrepancies)}")
    print("="*80)

    # Verify the fixes
    print("\nVerifying fixes...")
    verification_passed = True

    for role_id, comp_id, our_val, derik_val in discrepancies:
        result = db.session.execute(text("""
            SELECT role_competency_value
            FROM role_competency_matrix
            WHERE role_cluster_id = :role_id
              AND competency_id = :comp_id
              AND organization_id = 1
        """), {"role_id": role_id, "comp_id": comp_id})

        current_val = result.scalar()

        if current_val == derik_val:
            print(f"  [OK] Role {role_id}, Comp {comp_id}: value={current_val} (correct)")
        else:
            print(f"  [ERROR] Role {role_id}, Comp {comp_id}: value={current_val} (expected {derik_val})")
            verification_passed = False

    print("\n" + "="*80)
    if verification_passed:
        print("[SUCCESS] All discrepancies fixed and verified!")
        print("Our role_competency_matrix now EXACTLY matches Derik's data.")
    else:
        print("[ERROR] Some fixes failed verification")
    print("="*80)
