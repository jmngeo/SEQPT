from app import create_app, db
from app.models import NewSurveyUser, CompetencyAssessment, AdminUser

app = create_app()
app.app_context().push()

# Check CompetencyAssessment table for IDs 19 and 20
print("=== CompetencyAssessment table (assessments 19 and 20) ===")
assessments = CompetencyAssessment.query.filter(CompetencyAssessment.id.in_([19, 20])).all()
if assessments:
    for a in assessments:
        print(f"ID: {a.id}, Admin User ID: {a.admin_user_id}, Organization: {a.organization_id}")
        print(f"  Date: {a.assessment_date}, Status: {a.status}")
        # Get admin user info
        admin = AdminUser.query.get(a.admin_user_id)
        if admin:
            print(f"  Admin: {admin.username}, Role: {admin.role}")
        # Get app user info if linked
        if a.app_user_id:
            from app.models import AppUser
            app_user = AppUser.query.get(a.app_user_id)
            if app_user:
                print(f"  App User: {app_user.username}")
else:
    print("No assessments found with IDs 19 or 20 in CompetencyAssessment table")

# Get all CompetencyAssessment records to see what's there
print("\n=== ALL CompetencyAssessment records ===")
all_comp = CompetencyAssessment.query.order_by(CompetencyAssessment.id.desc()).limit(10).all()
print(f"Last 10 assessments:")
for ca in all_comp:
    admin = AdminUser.query.get(ca.admin_user_id)
    admin_name = admin.username if admin else "Unknown"
    app_username = "N/A"
    if ca.app_user_id:
        from app.models import AppUser
        app_user = AppUser.query.get(ca.app_user_id)
        if app_user:
            app_username = app_user.username
    print(f"ID: {ca.id}, Admin: {admin_name} (ID: {ca.admin_user_id}), App User: {app_username}, Date: {ca.assessment_date}")

# Check what the user 'satesate' (admin user) has
print("\n=== Looking for admin user 'satesate' ===")
admin_user = AdminUser.query.filter_by(username='satesate').first()
if admin_user:
    print(f"Found admin user: {admin_user.username} (ID: {admin_user.id}), Role: {admin_user.role}, Org: {admin_user.organization_id}")
    # Get assessments for this admin user
    admin_assessments = CompetencyAssessment.query.filter_by(admin_user_id=admin_user.id).all()
    print(f"  Total assessments: {len(admin_assessments)}")
    for a in admin_assessments:
        app_username = "N/A"
        if a.app_user_id:
            from app.models import AppUser
            app_user = AppUser.query.get(a.app_user_id)
            if app_user:
                app_username = app_user.username
        print(f"    ID: {a.id}, Date: {a.assessment_date}, App User: {app_username}")
else:
    print("Admin user 'satesate' not found")
