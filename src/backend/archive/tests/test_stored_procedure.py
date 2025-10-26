"""Test stored procedure execution"""
from app import create_app
from sqlalchemy import text
from models import db, UnknownRoleCompetencyMatrix

app = create_app()
app.app_context().push()

print("Calling stored procedure for test_dev_user...")
try:
    db.session.execute(
        text('CALL update_unknown_role_competency_values(:username, :organization_id);'),
        {'username': 'test_dev_user', 'organization_id': 1}
    )
    db.session.commit()
    print("Stored procedure called successfully")

    # Check results
    competencies = UnknownRoleCompetencyMatrix.query.filter_by(
        user_name='test_dev_user'
    ).all()

    print(f"\nCompetency entries created: {len(competencies)}")
    if competencies:
        print("\nFirst 10 competency values:")
        for c in competencies[:10]:
            print(f"  Competency {c.competency_id}: {c.role_competency_value}")
    else:
        print("WARNING: No competency entries created!")

except Exception as e:
    print(f"ERROR: {e}")
    import traceback
    traceback.print_exc()
