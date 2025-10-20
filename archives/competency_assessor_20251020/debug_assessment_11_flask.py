"""Debug script to check assessment 11 data using Flask app context."""
import sys
import os

# Add the app directory to path
sys.path.insert(0, os.path.dirname(__file__))

from app import create_app, db
from app.models import CompetencyAssessment, CompetencyResults, CompetencyMaxScores, Competency

app = create_app()

with app.app_context():
    assessment_id = 11

    print(f"\n=== ASSESSMENT {assessment_id} DETAILS ===\n")

    # Get assessment basic info
    assessment = CompetencyAssessment.query.filter_by(id=assessment_id).first()
    if not assessment:
        print(f"[ERROR] Assessment {assessment_id} not found!")
        sys.exit(1)

    print(f"Assessment ID: {assessment.id}")
    print(f"Admin User ID: {assessment.admin_user_id}")
    print(f"Role: {assessment.role}")
    print(f"Assessment Date: {assessment.assessment_date}")
    print(f"Assessment Type: {assessment.assessment_type}")

    # Get user scores for this assessment
    user_scores = CompetencyResults.query.filter_by(assessment_id=assessment_id).order_by(CompetencyResults.competency_name).all()

    print(f"\n=== USER SCORES ({len(user_scores)} competencies) ===")
    for score in user_scores:
        print(f"  {score.competency_name}: score={score.score}, area={score.competency_area}")

    # Get max/required scores for this assessment
    max_scores = db.session.query(
        CompetencyMaxScores.competency_id,
        Competency.competency_name,
        CompetencyMaxScores.max_score
    ).join(
        Competency, CompetencyMaxScores.competency_id == Competency.competency_id
    ).filter(
        CompetencyMaxScores.assessment_id == assessment_id
    ).order_by(Competency.competency_name).all()

    print(f"\n=== REQUIRED SCORES ({len(max_scores)} competencies) ===")
    for comp_id, comp_name, required in max_scores:
        print(f"  {comp_name} (ID {comp_id}): required={required}")

    # Check for Project Management specifically
    print(f"\n=== PROJECT MANAGEMENT ANALYSIS ===")
    pm_comps = Competency.query.filter(Competency.competency_name.ilike('%project%management%')).all()

    for comp in pm_comps:
        print(f"\nCompetency ID: {comp.competency_id}")
        print(f"Name: {comp.competency_name}")

        # Get user score
        user_score = CompetencyResults.query.filter_by(
            assessment_id=assessment_id,
            competency_id=comp.competency_id
        ).first()
        print(f"User Score: {user_score.score if user_score else 'N/A'}")

        # Get required score
        required = CompetencyMaxScores.query.filter_by(
            assessment_id=assessment_id,
            competency_id=comp.competency_id
        ).first()
        print(f"Required Score: {required.max_score if required else 'N/A'}")

    print("\n[OK] Debug complete")
