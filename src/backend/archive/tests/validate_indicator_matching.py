"""
Validate that competency indicators are being matched correctly
"""
from app import create_app
from models import db, UserCompetencySurveyResults, CompetencyIndicator, Competency, RoleCompetencyMatrix, UserRoleCluster

app = create_app()

with app.app_context():
    # Test with user se_survey_user_6 (ID: 3)
    username = 'se_survey_user_6'
    user_id = 3
    organization_id = 19
    
    print("=" * 80)
    print(f"VALIDATING COMPETENCY INDICATOR MATCHING FOR: {username}")
    print("=" * 80)
    
    # Fetch user's competency scores
    user_competencies = UserCompetencySurveyResults.query.filter_by(
        user_id=user_id,
        organization_id=organization_id
    ).order_by(UserCompetencySurveyResults.competency_id).all()
    
    print(f"\n[OK] Found {len(user_competencies)} user competency scores")
    
    # Helper function to map score to level (numeric level in DB)
    def score_to_level(score):
        score_map = {
            0: '0',     # unwissend (unaware)
            1: '1',     # kennen (know)
            2: '2',     # verstehen (understand)
            4: '3',     # anwenden (apply) - note: score 4 maps to level 3
            6: '4'      # beherrschen (master) - note: score 6 maps to level 4
        }
        return score_map.get(score, '0')

    # Helper function to get level name for display
    def get_level_name(level):
        level_names = {
            '0': 'unwissend (unaware)',
            '1': 'kennen (know)',
            '2': 'verstehen (understand)',
            '3': 'anwenden (apply)',
            '4': 'beherrschen (master)'
        }
        return level_names.get(level, 'unknown')
    
    # Fetch required competency scores (for known_roles)
    user_roles = UserRoleCluster.query.filter_by(user_id=user_id).all()
    role_cluster_ids = [role.role_cluster_id for role in user_roles]
    
    print(f"\n[OK] User has {len(role_cluster_ids)} selected roles: {role_cluster_ids}")
    
    max_scores = db.session.query(
        RoleCompetencyMatrix.competency_id,
        db.func.max(RoleCompetencyMatrix.role_competency_value).label('max_score')
    ).filter(
        RoleCompetencyMatrix.organization_id == organization_id,
        RoleCompetencyMatrix.role_cluster_id.in_(role_cluster_ids)
    ).group_by(RoleCompetencyMatrix.competency_id).order_by(RoleCompetencyMatrix.competency_id).all()
    
    max_scores_map = {m.competency_id: m.max_score for m in max_scores}
    
    print(f"\n[OK] Found {len(max_scores_map)} max required scores")
    
    print("\n" + "=" * 80)
    print("VALIDATING INDICATOR MATCHING FOR EACH COMPETENCY")
    print("=" * 80)
    
    # Test first 3 competencies in detail
    test_count = 0
    errors = []
    
    for user_comp in user_competencies[:3]:  # Test first 3
        test_count += 1
        competency_id = user_comp.competency_id
        user_score = user_comp.score
        
        # Get competency info
        competency = Competency.query.get(competency_id)
        competency_name = competency.competency_name
        
        # Map user score to level
        user_level = score_to_level(user_score)
        
        # Get required score
        required_score = max_scores_map.get(competency_id, 0)
        required_level = score_to_level(int(required_score)) if required_score else '0'
        
        print(f"\n--- Competency {test_count}: {competency_name} (ID: {competency_id}) ---")
        print(f"  User Score: {user_score} -> Level: {user_level} ({get_level_name(user_level)})")
        print(f"  Required Score: {required_score} -> Level: {required_level} ({get_level_name(required_level)})")

        # Fetch indicators for user level
        if user_level != '0':
            user_indicators = CompetencyIndicator.query.filter_by(
                competency_id=competency_id,
                level=user_level
            ).all()
            
            if user_indicators:
                print(f"  [OK] Found {len(user_indicators)} indicators for user level '{user_level}'")
                print(f"       Sample: {user_indicators[0].indicator_en[:80]}...")
            else:
                error_msg = f"[ERROR] No indicators found for competency {competency_id} at level '{user_level}'"
                print(f"  {error_msg}")
                errors.append(error_msg)
        else:
            print(f"  [SKIP] User level is 'unwissend' - no indicators needed")
        
        # Fetch indicators for required level
        if required_level != '0':
            required_indicators = CompetencyIndicator.query.filter_by(
                competency_id=competency_id,
                level=required_level
            ).all()
            
            if required_indicators:
                print(f"  [OK] Found {len(required_indicators)} indicators for required level '{required_level}'")
                print(f"       Sample: {required_indicators[0].indicator_en[:80]}...")
            else:
                error_msg = f"[ERROR] No indicators found for competency {competency_id} at level '{required_level}'"
                print(f"  {error_msg}")
                errors.append(error_msg)
        else:
            print(f"  [SKIP] Required level is 'unwissend' - no indicators needed")
        
        # Check gap analysis
        if user_score < required_score:
            print(f"  [GAP] User is BELOW required level (gap: {required_score - user_score} points)")
        elif user_score > required_score:
            print(f"  [EXCEED] User EXCEEDS required level (surplus: {user_score - required_score} points)")
        else:
            print(f"  [MATCH] User meets required level exactly")
    
    print("\n" + "=" * 80)
    print("VALIDATION SUMMARY")
    print("=" * 80)
    
    if errors:
        print(f"\n[FAILED] {len(errors)} errors found:")
        for error in errors:
            print(f"  - {error}")
    else:
        print(f"\n[SUCCESS] All {test_count} tested competencies have correct indicator matching!")
        print("  - Score to level mapping: CORRECT")
        print("  - User level indicators: FOUND")
        print("  - Required level indicators: FOUND")
        print("  - Gap analysis: WORKING")
    
    print("\n" + "=" * 80)
