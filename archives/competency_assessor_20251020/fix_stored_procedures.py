"""Fix stored procedures to use numeric levels instead of German text"""

from app import create_app, db
from sqlalchemy import text

# Fixed SQL - use numeric levels matching the database
sql_fix = """
CREATE OR REPLACE FUNCTION public.get_competency_results(p_username character varying, p_organization_id integer)
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
        SELECT competency_id, MAX(role_competency_value) AS max_score
        FROM role_competency_matrix
        WHERE organization_id = p_organization_id
          AND role_cluster_id IN (
              SELECT role_cluster_id
              FROM user_role_cluster
              WHERE user_id IN (SELECT id FROM app_user WHERE username = p_username AND organization_id = p_organization_id)
              AND role_cluster_id NOT IN (40004, 70007)
          )
        GROUP BY competency_id
    ),
    required_vs_recorded AS (
        SELECT rec.*, req.max_score
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
            AND rr.max_score = i.level_assigned_score
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
        SELECT rec.*, req.max_score
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
            AND rr.max_score = i.level_assigned_score
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
        print("[INFO] Fixing stored procedures to use numeric levels...")
        db.session.execute(text(sql_fix))
        db.session.commit()
        print("[SUCCESS] Stored procedures fixed!")

        # Test it
        print("[INFO] Testing fixed procedure...")
        result = db.session.execute(text('SELECT * FROM public.get_competency_results(:u, :o) LIMIT 3'), {'u': 'se_survey_user_51', 'o': 1}).fetchall()
        print(f"[SUCCESS] Test returned {len(result)} rows")
        for row in result[:2]:
            print(f"  {row[1]}: user_level={row[2]}, required_level={row[4]}")

    except Exception as e:
        print(f"[ERROR] Failed: {e}")
        db.session.rollback()
