"""
Script to check assessment data for user satesateemp
"""
from app import create_app, db
from app.models import AppUser, UserCompetencySurveyResults, Competency, UserRoleCluster, RoleCompetencyMatrix
from sqlalchemy import func

def check_assessment_data():
    app = create_app()

    with app.app_context():
        print("=" * 80)
        print("ASSESSMENT DATA CHECK")
        print("=" * 80)

        # Find the latest survey user (check both recent users)
        user = AppUser.query.order_by(AppUser.id.desc()).first()
        if not user:
            print("No AppUser found!")
            return

        print(f"\nUser: {user.username}")
        print(f"User ID: {user.id}")
        print(f"Organization ID: {user.organization_id}")

        # Check user role
        user_role = UserRoleCluster.query.filter_by(user_id=user.id).first()
        if user_role:
            print(f"Role Cluster ID: {user_role.role_cluster_id}")
        else:
            print("No role cluster assigned!")

        # Check survey data
        survey_data = UserCompetencySurveyResults.query.filter_by(user_id=user.id).all()
        print(f"\nTotal survey responses: {len(survey_data)}")

        # Count unique competencies in responses
        unique_competencies = set()
        for data in survey_data:
            unique_competencies.add(data.competency_id)

        print(f"Unique competencies answered: {len(unique_competencies)}")

        # Check total competencies in database
        total_competencies = Competency.query.count()
        print(f"\nTotal competencies in database: {total_competencies}")

        # Check competency areas distribution
        areas = db.session.query(
            Competency.competency_area,
            func.count(Competency.id).label('count')
        ).group_by(Competency.competency_area).all()

        print(f"\nCompetency Areas Distribution:")
        for area_name, count in areas:
            print(f"  - {area_name}: {count} competencies")

        # Show sample survey data
        print("\n" + "=" * 80)
        print("SAMPLE SURVEY RESPONSES (first 5)")
        print("=" * 80)
        for i, data in enumerate(survey_data[:5]):
            comp = Competency.query.get(data.competency_id)
            print(f"\n{i+1}. Competency: {comp.competency_name if comp else 'Unknown'}")
            print(f"   Score: {data.score}")

        # Check role_competency_matrix for this role
        if user_role:
            print("\n" + "=" * 80)
            print("ROLE-COMPETENCY MATRIX CHECK")
            print("=" * 80)

            role_competencies = RoleCompetencyMatrix.query.filter_by(
                role_cluster_id=user_role.role_cluster_id,
                organization_id=user.organization_id
            ).all()

            print(f"Role competencies defined for this role: {len(role_competencies)}")
            print("\nFirst 5 role competencies:")
            for i, rc in enumerate(role_competencies[:5]):
                comp = Competency.query.get(rc.competency_id)
                print(f"  {i+1}. {comp.competency_name if comp else 'Unknown'}: value={rc.role_competency_value}")

if __name__ == '__main__':
    check_assessment_data()
