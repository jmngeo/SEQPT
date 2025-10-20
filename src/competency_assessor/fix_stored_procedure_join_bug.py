"""
Fix the stored procedure join bug where max_score isn't mapped before joining with indicators.
"""
from app import create_app, db
from sqlalchemy import text

# Fixed SQL - add mapping for max_score before the join
sql_fix = """
CREATE OR REPLACE FUNCTION public.get_unknown_role_competency_results(p_username character varying, p_organization_id integer)
RETURNS TABLE(
    competency_area text,
    competency_name text,
    user_recorded_level text,
    user_recorded_level_competency_indicator text,
    user_required_level text,
    user_required_level_competency_indicator text
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH recorded_competencies AS (
        SELECT sr.competency_id,
               c.competency_area::TEXT,
               c.competency_name::TEXT,
               sr.score AS user_score
        FROM user_se_competency_survey_results sr
        LEFT JOIN competency c ON sr.competency_id = c.id
        WHERE sr.user_id IN (SELECT id FROM app_user WHERE username = p_username AND organization_id = p_organization_id)
    ),
    required_competencies AS (
        SELECT competency_id, role_competency_value AS max_score
        FROM unknown_role_competency_matrix urcm
        WHERE user_name = p_username AND organization_id = p_organization_id
    ),
    required_vs_recorded AS (
        SELECT rec.*,
               req.max_score,
               -- MAP max_score from survey levels (0-4) to indicator levels (0,1,2,4,6)
               CASE
                   WHEN req.max_score = 0 THEN 0
                   WHEN req.max_score = 1 THEN 1
                   WHEN req.max_score = 2 THEN 2
                   WHEN req.max_score = 3 THEN 4
                   WHEN req.max_score = 4 THEN 6
                   ELSE 0
               END AS max_score_mapped
        FROM recorded_competencies rec
        LEFT JOIN required_competencies req ON rec.competency_id = req.competency_id
    ),
    competency_indicators_with_score AS (
        SELECT competency_id, "level",
               CASE
                   WHEN "level" = '1' THEN 1
                   WHEN "level" = '2' THEN 2
                   WHEN "level" = '3' THEN 4
                   WHEN "level" = '4' THEN 6
                   ELSE 0
               END AS level_assigned_score,
               STRING_AGG(indicator_en, '. ') AS indicator_en
        FROM competency_indicators
        GROUP BY competency_id, "level"
    ),
    required_vs_recorded_with_indicators_joined_by_rec AS (
        SELECT rr.*, i.level AS recorded_level, i.indicator_en AS recorded_level_indicators
        FROM required_vs_recorded rr
        LEFT JOIN competency_indicators_with_score i
            ON rr.competency_id = i.competency_id
            AND rr.user_score = i.level_assigned_score
    ),
    required_vs_recorded_with_indicators_joined_by_req AS (
        SELECT rr.*, i.level AS required_level, i.indicator_en AS required_level_indicators
        FROM required_vs_recorded_with_indicators_joined_by_rec rr
        LEFT JOIN competency_indicators_with_score i
            ON rr.competency_id = i.competency_id
            -- FIX: Use max_score_mapped instead of max_score
            AND rr.max_score_mapped = i.level_assigned_score
    )
    SELECT rrw.competency_area::TEXT,
           rrw.competency_name::TEXT,
           COALESCE(rrw.recorded_level, '0')::TEXT AS user_recorded_level,
           COALESCE(rrw.recorded_level_indicators, 'You are unaware or lack knowledge in this competency area')::TEXT AS user_recorded_level_competency_indicator,
           COALESCE(rrw.required_level, '0')::TEXT AS user_required_level,
           COALESCE(rrw.required_level_indicators, 'No specific requirement for this competency')::TEXT AS user_required_level_competency_indicator
    FROM required_vs_recorded_with_indicators_joined_by_req rrw
    ORDER BY rrw.competency_area;
END;
$$;
"""

app = create_app()
with app.app_context():
    try:
        print("=" * 80)
        print("FIXING STORED PROCEDURE JOIN BUG")
        print("=" * 80)
        print("\n[INFO] The bug: max_score (survey 0-4) wasn't mapped before joining with")
        print("       level_assigned_score (indicator 0,1,2,4,6)")
        print("       Result: max_score=3 never matched level_assigned_score=4")
        print("       -> required_level became NULL -> defaulted to '0'\n")

        print("[INFO] Applying fix (mapping max_score before join)...")
        db.session.execute(text(sql_fix))
        db.session.commit()
        print("[SUCCESS] Stored procedure fixed!\n")

        # Test it with the problematic user
        print("[INFO] Testing with user: seqpt_user_1760279481364")
        print("-" * 80)

        result = db.session.execute(
            text("""
            SELECT competency_name, user_recorded_level, user_required_level
            FROM public.get_unknown_role_competency_results(:u, :o)
            WHERE competency_name IN ('Leadership', 'Project Management', 'Information Management')
            """),
            {'u': 'seqpt_user_1760279481364', 'o': 1}
        ).fetchall()

        print("\nResults AFTER fix:")
        for comp_name, user_level, required_level in result:
            print(f"  {comp_name:30s} | User: {user_level:2s} | Required: {required_level:2s}")

        print("\n" + "=" * 80)
        print("VERIFICATION")
        print("=" * 80)
        print("Expected:")
        print("  Leadership:             User: 1  | Required: 3  (was showing 0 - BUG)")
        print("  Project Management:     User: 3  | Required: 3  (was showing 0 - BUG)")
        print("  Information Management: User: 1  | Required: 3  (was showing 0 - BUG)")
        print("\n[INFO] If the numbers above match, the fix is working!")

    except Exception as e:
        print(f"\n[ERROR] Failed: {e}")
        import traceback
        traceback.print_exc()
        db.session.rollback()
