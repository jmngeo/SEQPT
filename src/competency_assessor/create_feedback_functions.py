"""Create stored procedures for feedback generation"""

import psycopg2

# Database connection (using working credentials)
DATABASE_URL = 'postgresql://postgres:root@localhost:5432/competency_assessment'

# SQL for stored procedures
sql_get_competency_results = """
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
                   WHEN "level" = 'kennen' THEN 1
                   WHEN "level" = 'verstehen' THEN 2
                   WHEN "level" = 'anwenden' THEN 4
                   WHEN "level" = 'beherrschen' THEN 6
               END AS level_assigned_score,
               STRING_AGG(indicator_en, '. ') AS indicator_en
        FROM competency_indicators
        GROUP BY competency_id, "level"
    ),
    required_vs_recorded_with_indicators_joined_by_req AS (
        SELECT rr.*, i.level AS recorded_level, i.indicator_en AS recorded_level_indicators
        FROM required_vs_recorded rr
        LEFT JOIN competency_indicators_with_score i
            ON rr.competency_id = i.competency_id
            AND rr.user_score = i.level_assigned_score
    ),
    required_vs_recorded_with_indicators_joined_by_req_joined_by_rec AS (
        SELECT rr.*, i.level AS required_level, i.indicator_en AS required_level_indicators
        FROM required_vs_recorded_with_indicators_joined_by_req rr
        LEFT JOIN competency_indicators_with_score i
            ON rr.competency_id = i.competency_id
            AND rr.max_score = i.level_assigned_score
    )
    SELECT rrw.competency_area::TEXT,
           rrw.competency_name::TEXT,
           COALESCE(rrw.recorded_level, 'unwissend')::TEXT AS user_recorded_level,
           COALESCE(rrw.recorded_level_indicators, 'You are unaware or lacks knowledge in this competency area')::TEXT AS user_recorded_level_competency_indicator,
           rrw.required_level::TEXT AS user_required_level,
           rrw.required_level_indicators::TEXT AS user_required_level_competency_indicator
    FROM required_vs_recorded_with_indicators_joined_by_req_joined_by_rec rrw
    ORDER BY rrw.competency_area;
END;
$$;
"""

sql_get_unknown_role_competency_results = """
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
                   WHEN "level" = 'kennen' THEN 1
                   WHEN "level" = 'verstehen' THEN 2
                   WHEN "level" = 'anwenden' THEN 4
                   WHEN "level" = 'beherrschen' THEN 6
               END AS level_assigned_score,
               STRING_AGG(indicator_en, '. ') AS indicator_en
        FROM competency_indicators
        GROUP BY competency_id, "level"
    ),
    required_vs_recorded_with_indicators_joined_by_req AS (
        SELECT rr.*, i.level AS recorded_level, i.indicator_en AS recorded_level_indicators
        FROM required_vs_recorded rr
        LEFT JOIN competency_indicators_with_score i
            ON rr.competency_id = i.competency_id
            AND rr.user_score = i.level_assigned_score
    ),
    required_vs_recorded_with_indicators_joined_by_req_joined_by_rec AS (
        SELECT rr.*, i.level AS required_level, i.indicator_en AS required_level_indicators
        FROM required_vs_recorded_with_indicators_joined_by_req rr
        LEFT JOIN competency_indicators_with_score i
            ON rr.competency_id = i.competency_id
            AND rr.max_score = i.level_assigned_score
    )
    SELECT rrw.competency_area::TEXT,
           rrw.competency_name::TEXT,
           COALESCE(rrw.recorded_level, 'unwissend')::TEXT AS user_recorded_level,
           COALESCE(rrw.recorded_level_indicators, 'You are unaware or lacks knowledge in this competency area')::TEXT AS user_recorded_level_competency_indicator,
           rrw.required_level::TEXT AS user_required_level,
           rrw.required_level_indicators::TEXT AS user_required_level_competency_indicator
    FROM required_vs_recorded_with_indicators_joined_by_req_joined_by_rec rrw
    ORDER BY rrw.competency_area;
END;
$$;
"""

try:
    conn = psycopg2.connect(DATABASE_URL)
    cursor = conn.cursor()

    print("[INFO] Creating get_competency_results function...")
    cursor.execute(sql_get_competency_results)
    conn.commit()
    print("[SUCCESS] get_competency_results function created")

    print("[INFO] Creating get_unknown_role_competency_results function...")
    cursor.execute(sql_get_unknown_role_competency_results)
    conn.commit()
    print("[SUCCESS] get_unknown_role_competency_results function created")

    # Verify functions exist
    cursor.execute("""
        SELECT routine_name
        FROM information_schema.routines
        WHERE routine_schema = 'public'
        AND routine_name IN ('get_competency_results', 'get_unknown_role_competency_results')
    """)
    functions = cursor.fetchall()
    print(f"[INFO] Found {len(functions)} stored functions:")
    for func in functions:
        print(f"  - {func[0]}")

    cursor.close()
    conn.close()
    print("[SUCCESS] All stored procedures created successfully!")

except Exception as e:
    print(f"[ERROR] Failed to create stored procedures: {e}")
