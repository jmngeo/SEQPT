import os
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app import create_app
from app.models import Phase1Maturity, Phase1Roles, Phase1TargetGroup

app = create_app()

with app.app_context():
    # Check latest maturity assessments for org 24
    print("\n=== Latest Maturity Assessments for Org 24 ===")
    maturity_records = Phase1Maturity.query.filter_by(org_id=24).order_by(Phase1Maturity.id.desc()).limit(3).all()

    for m in maturity_records:
        print(f"\nMaturity ID: {m.id}")
        print(f"  SE Processes: {m.se_processes}")
        print(f"  Rollout Scope: {m.rollout_scope}")
        print(f"  Final Score: {m.final_score}")
        print(f"  Maturity Level: {m.maturity_level}")

        # Check if this maturity has roles
        roles = Phase1Roles.query.filter_by(maturity_id=m.id).all()
        print(f"  Roles Count: {len(roles)}")
        if roles:
            for r in roles[:5]:  # Show first 5
                print(f"    - {r.role_name} ({r.role_type})")

        # Check if this maturity has target group
        target_group = Phase1TargetGroup.query.filter_by(maturity_id=m.id).first()
        if target_group:
            print(f"  Target Group: {target_group.size_range} ({target_group.size_category})")
            print(f"  Estimated Count: {target_group.estimated_count}")
        else:
            print(f"  Target Group: None")
