"""
Apply the 11 discrepancy fixes to role_competency_matrix (auto-apply version)
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
        (5, 1, 4, 2),    # Specialist Developer
        (5, 7, 4, 2),
        (5, 14, 4, 2),
        (5, 15, 2, 4),
        (5, 17, 0, 1),
        (9, 1, 2, 4),    # V&V Operator
        (9, 10, 1, 4),
        (9, 14, 2, 4),
        (9, 15, 4, 2),
        (10, 14, 1, 2),  # Service Technician
        (10, 17, 2, 4),
    ]

    role_names = {
        5: "Specialist Developer",
        9: "Verification and Validation (V&V) Operator",
        10: "Service Technician"
    }

    print(f"\nApplying {len(discrepancies)} fixes to match Derik's exact values:\n")

    fixed_count = 0
    errors = []

    for role_id, comp_id, our_val, derik_val in discrepancies:
        role_name = role_names.get(role_id, f"Role {role_id}")

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
            print(f"  [OK] {role_name} (Role {role_id}), Comp {comp_id:2d}: {our_val} -> {derik_val}")
        else:
            error_msg = f"Role {role_id}, Comp {comp_id}: NOT FOUND"
            errors.append(error_msg)
            print(f"  [ERROR] {error_msg}")

    db.session.commit()

    print("\n" + "="*80)
    print(f"FIXES APPLIED: {fixed_count}/{len(discrepancies)}")
    if errors:
        print(f"ERRORS: {len(errors)}")
        for err in errors:
            print(f"  - {err}")
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
        role_name = role_names.get(role_id, f"Role {role_id}")

        if current_val == derik_val:
            print(f"  [OK] {role_name}, Comp {comp_id:2d}: {current_val} (correct)")
        else:
            print(f"  [ERROR] {role_name}, Comp {comp_id:2d}: {current_val} (expected {derik_val})")
            verification_passed = False

    print("\n" + "="*80)
    if verification_passed and fixed_count == len(discrepancies):
        print("[SUCCESS] All 11 discrepancies fixed and verified!")
        print("Our role_competency_matrix now EXACTLY matches Derik's data.")
    else:
        print("[WARNING] Some fixes may have failed")
    print("="*80)
