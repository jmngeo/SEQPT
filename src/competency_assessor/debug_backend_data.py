"""
Debug what data the backend is sending to LLM vs what frontend displays.
"""
from app import create_app, db
from sqlalchemy import text
import json

app = create_app()

with app.app_context():
    username = 'seqpt_user_1760279481364'
    organization_id = 1

    print("=" * 80)
    print(f"BACKEND DATA FLOW FOR USER: {username}")
    print("=" * 80)

    # 1. What does the stored procedure return?
    print("\n1. STORED PROCEDURE OUTPUT (what LLM receives):")
    print("-" * 80)

    sp_result = db.session.execute(
        text("""
        SELECT competency_area, competency_name,
               user_recorded_level, user_required_level
        FROM public.get_unknown_role_competency_results(:username, :org_id)
        ORDER BY competency_name
        """),
        {"username": username, "org_id": organization_id}
    ).fetchall()

    for area, name, user_level, required_level in sp_result[:10]:
        print(f"{name:40s} | User: {user_level:2s} | Required: {required_level if required_level else 'None':>6s}")

    # 2. What's in unknown_role_competency_matrix?
    print("\n2. UNKNOWN_ROLE_COMPETENCY_MATRIX (raw required levels):")
    print("-" * 80)

    matrix_result = db.session.execute(
        text("""
        SELECT c.competency_name, urcm.role_competency_value
        FROM unknown_role_competency_matrix urcm
        JOIN competency c ON c.id = urcm.competency_id
        WHERE urcm.user_name = :username
          AND urcm.organization_id = :org_id
        ORDER BY c.competency_name
        """),
        {"username": username, "org_id": organization_id}
    ).fetchall()

    for name, required_val in matrix_result[:10]:
        print(f"{name:40s} | Required: {required_val}")

    # 3. What does the API endpoint return?
    print("\n3. API ENDPOINT RESPONSE (what frontend receives):")
    print("-" * 80)

    # Simulate what the API returns
    from app.models import AppUser, UserCompetencySurveyResults, Competency

    user = AppUser.query.filter_by(username=username).first()
    if user:
        user_competencies = UserCompetencySurveyResults.query.filter_by(
            user_id=user.id,
            organization_id=organization_id
        ).order_by(UserCompetencySurveyResults.competency_id).all()

        competencies = Competency.query.filter(
            Competency.id.in_([u.competency_id for u in user_competencies])
        ).order_by(Competency.id).all()

        competency_info_map = {comp.id: comp.competency_name for comp in competencies}

        user_scores = [
            {
                'competency_id': u.competency_id,
                'competency_name': competency_info_map[u.competency_id],
                'score': u.score
            }
            for u in user_competencies
        ]

        from app.models import UnknownRoleCompetencyMatrix
        max_scores = db.session.query(
            UnknownRoleCompetencyMatrix.competency_id,
            UnknownRoleCompetencyMatrix.role_competency_value.label('max_score')
        ).filter(
            UnknownRoleCompetencyMatrix.organization_id == organization_id,
            UnknownRoleCompetencyMatrix.user_name == username
        ).all()

        max_scores_dict = [{'competency_id': m.competency_id, 'max_score': m.max_score} for m in max_scores]

        print("User Scores (first 5):")
        for score in user_scores[:5]:
            max_score_entry = next((m for m in max_scores_dict if m['competency_id'] == score['competency_id']), None)
            required = max_score_entry['max_score'] if max_score_entry else 'Not found'
            print(f"  {score['competency_name']:40s} | User: {score['score']} | Required: {required}")

    # 4. Check specific problematic competencies
    print("\n4. SPECIFIC COMPETENCY CHECKS:")
    print("-" * 80)

    for comp_name in ['Leadership', 'Project Management']:
        print(f"\n{comp_name}:")

        # Get competency ID
        comp = Competency.query.filter_by(competency_name=comp_name).first()
        if not comp:
            print("  NOT FOUND in competency table")
            continue

        print(f"  Competency ID: {comp.id}")

        # User's survey response
        if user:
            user_result = UserCompetencySurveyResults.query.filter_by(
                user_id=user.id,
                competency_id=comp.id
            ).first()
            print(f"  User Survey Score: {user_result.score if user_result else 'NOT FOUND'}")

        # Matrix required level
        matrix_entry = UnknownRoleCompetencyMatrix.query.filter_by(
            user_name=username,
            organization_id=organization_id,
            competency_id=comp.id
        ).first()
        print(f"  Matrix Required Level: {matrix_entry.role_competency_value if matrix_entry else 'NOT FOUND'}")

        # Stored procedure output
        sp_output = db.session.execute(
            text("""
            SELECT user_recorded_level, user_required_level
            FROM public.get_unknown_role_competency_results(:username, :org_id)
            WHERE competency_name = :comp_name
            """),
            {"username": username, "org_id": organization_id, "comp_name": comp_name}
        ).fetchone()
        if sp_output:
            print(f"  Stored Proc User Level: {sp_output[0]}")
            print(f"  Stored Proc Required Level: {sp_output[1]}")
        else:
            print("  NOT RETURNED by stored procedure")
