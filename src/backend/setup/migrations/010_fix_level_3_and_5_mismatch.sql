-- Migration 010: Fix Level 3 and 5 Data Mismatch
-- Date: 2025-11-15
-- Description: Maps level 3 to 4 and level 5 to 6 to align with learning objectives templates
-- Affects: role_competency_matrix, unknown_role_competency_matrix, user_se_competency_survey_results

-- =============================================================================
-- PRE-MIGRATION VERIFICATION
-- =============================================================================

-- Check current state before migration
DO $$
DECLARE
    role_comp_3_count INTEGER;
    unknown_comp_3_count INTEGER;
    survey_3_count INTEGER;
    survey_5_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO role_comp_3_count FROM role_competency_matrix WHERE role_competency_value = 3;
    SELECT COUNT(*) INTO unknown_comp_3_count FROM unknown_role_competency_matrix WHERE role_competency_value = 3;
    SELECT COUNT(*) INTO survey_3_count FROM user_se_competency_survey_results WHERE score = 3;
    SELECT COUNT(*) INTO survey_5_count FROM user_se_competency_survey_results WHERE score = 5;

    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'PRE-MIGRATION STATE';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'role_competency_matrix with value 3: %', role_comp_3_count;
    RAISE NOTICE 'unknown_role_competency_matrix with value 3: %', unknown_comp_3_count;
    RAISE NOTICE 'user_se_competency_survey_results with score 3: %', survey_3_count;
    RAISE NOTICE 'user_se_competency_survey_results with score 5: %', survey_5_count;
    RAISE NOTICE '=================================================================';
END $$;

-- =============================================================================
-- MIGRATION STEP 1: Update role_competency_matrix
-- =============================================================================

RAISE NOTICE 'Step 1: Updating role_competency_matrix (3 -> 4)...';

UPDATE role_competency_matrix
SET role_competency_value = 4
WHERE role_competency_value = 3;

RAISE NOTICE 'Step 1: Complete';

-- =============================================================================
-- MIGRATION STEP 2: Update unknown_role_competency_matrix
-- =============================================================================

RAISE NOTICE 'Step 2: Updating unknown_role_competency_matrix (3 -> 4)...';

UPDATE unknown_role_competency_matrix
SET role_competency_value = 4
WHERE role_competency_value = 3;

RAISE NOTICE 'Step 2: Complete';

-- =============================================================================
-- MIGRATION STEP 3: Update user_se_competency_survey_results (score 3 -> 4)
-- =============================================================================

RAISE NOTICE 'Step 3: Updating user_se_competency_survey_results (3 -> 4)...';

UPDATE user_se_competency_survey_results
SET score = 4
WHERE score = 3;

RAISE NOTICE 'Step 3: Complete';

-- =============================================================================
-- MIGRATION STEP 4: Update user_se_competency_survey_results (score 5 -> 6)
-- =============================================================================

RAISE NOTICE 'Step 4: Updating user_se_competency_survey_results (5 -> 6)...';

UPDATE user_se_competency_survey_results
SET score = 6
WHERE score = 5;

RAISE NOTICE 'Step 4: Complete';

-- =============================================================================
-- MIGRATION STEP 5: Recreate stored procedures with corrected mapping
-- =============================================================================

RAISE NOTICE 'Step 5: Recreating stored procedures...';

-- 5a. Update update_role_competency_matrix procedure
CREATE OR REPLACE PROCEDURE public.update_role_competency_matrix(IN _organization_id integer)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Step 1: Delete existing entries for the given organization_id
    DELETE FROM public.role_competency_matrix
    WHERE organization_id = _organization_id;

    -- Step 2: Calculate and insert role-competency relationships
    -- Formula: role_competency_value = role_process_value * process_competency_value
    INSERT INTO public.role_competency_matrix (role_cluster_id, competency_id, role_competency_value, organization_id)
    SELECT
        rpm.role_cluster_id,
        pcm.competency_id,
        MAX(
            CASE
                -- Multiply role_process_value and process_competency_value
                WHEN rpm.role_process_value * pcm.process_competency_value = 0 THEN 0
                WHEN rpm.role_process_value * pcm.process_competency_value = 1 THEN 1
                WHEN rpm.role_process_value * pcm.process_competency_value = 2 THEN 2
                WHEN rpm.role_process_value * pcm.process_competency_value = 3 THEN 4  -- FIXED: Map level 3 to 4
                WHEN rpm.role_process_value * pcm.process_competency_value = 4 THEN 4
                WHEN rpm.role_process_value * pcm.process_competency_value = 6 THEN 6
                ELSE -100  -- Invalid combination
            END
        ) AS role_competency_value,
        _organization_id
    FROM
        public.role_process_matrix rpm
    JOIN
        public.process_competency_matrix pcm
    ON
        rpm.iso_process_id = pcm.iso_process_id
    WHERE
        rpm.organization_id = _organization_id
    GROUP BY
        rpm.role_cluster_id, pcm.competency_id;

    RAISE NOTICE 'Role-Competency matrix recalculated for organization_id %', _organization_id;
END;
$$;

-- 5b. Update update_unknown_role_competency_values procedure
CREATE OR REPLACE PROCEDURE public.update_unknown_role_competency_values(
    IN input_user_name text,
    IN input_organization_id integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Delete existing entries for the user and organization
    DELETE FROM unknown_role_competency_matrix
    WHERE user_name = input_user_name
      AND organization_id = input_organization_id;

    -- Calculate competency requirements from process involvement
    -- Formula: role_competency_value = role_process_value * process_competency_value
    INSERT INTO unknown_role_competency_matrix (user_name, competency_id, role_competency_value, organization_id)
    SELECT
        urpm.user_name::VARCHAR(50),
        pcm.competency_id,
        MAX(
            CASE
                WHEN urpm.role_process_value * pcm.process_competency_value = 0 THEN 0
                WHEN urpm.role_process_value * pcm.process_competency_value = 1 THEN 1
                WHEN urpm.role_process_value * pcm.process_competency_value = 2 THEN 2
                WHEN urpm.role_process_value * pcm.process_competency_value = 3 THEN 4  -- FIXED: Map level 3 to 4
                WHEN urpm.role_process_value * pcm.process_competency_value = 4 THEN 4
                WHEN urpm.role_process_value * pcm.process_competency_value = 6 THEN 6
                ELSE -100
            END
        ) AS role_competency_value,
        input_organization_id AS organization_id
    FROM public.unknown_role_process_matrix urpm
    JOIN public.process_competency_matrix pcm
    ON urpm.iso_process_id = pcm.iso_process_id
    WHERE urpm.organization_id = input_organization_id
      AND urpm.user_name = input_user_name
    GROUP BY urpm.user_name, pcm.competency_id;

    RAISE NOTICE 'Unknown role competency values updated for user % in organization %', input_user_name, input_organization_id;
END;
$$;

RAISE NOTICE 'Step 5: Complete';

-- =============================================================================
-- MIGRATION STEP 6: Update constraints to prevent future level 3 values
-- =============================================================================

RAISE NOTICE 'Step 6: Updating constraints...';

-- Drop old constraint and add new one for role_competency_matrix
ALTER TABLE role_competency_matrix
    DROP CONSTRAINT IF EXISTS role_competency_matrix_role_competency_value_check;

ALTER TABLE role_competency_matrix
    ADD CONSTRAINT role_competency_matrix_role_competency_value_check
    CHECK (role_competency_value = ANY (ARRAY[-100, 0, 1, 2, 4, 6]));

RAISE NOTICE 'Step 6: Complete';

-- =============================================================================
-- POST-MIGRATION VERIFICATION
-- =============================================================================

DO $$
DECLARE
    role_comp_3_count INTEGER;
    unknown_comp_3_count INTEGER;
    survey_3_count INTEGER;
    survey_5_count INTEGER;
    role_comp_4_count INTEGER;
    unknown_comp_4_count INTEGER;
    survey_4_count INTEGER;
    survey_6_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO role_comp_3_count FROM role_competency_matrix WHERE role_competency_value = 3;
    SELECT COUNT(*) INTO unknown_comp_3_count FROM unknown_role_competency_matrix WHERE role_competency_value = 3;
    SELECT COUNT(*) INTO survey_3_count FROM user_se_competency_survey_results WHERE score = 3;
    SELECT COUNT(*) INTO survey_5_count FROM user_se_competency_survey_results WHERE score = 5;

    SELECT COUNT(*) INTO role_comp_4_count FROM role_competency_matrix WHERE role_competency_value = 4;
    SELECT COUNT(*) INTO unknown_comp_4_count FROM unknown_role_competency_matrix WHERE role_competency_value = 4;
    SELECT COUNT(*) INTO survey_4_count FROM user_se_competency_survey_results WHERE score = 4;
    SELECT COUNT(*) INTO survey_6_count FROM user_se_competency_survey_results WHERE score = 6;

    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'POST-MIGRATION STATE';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'role_competency_matrix with value 3: % (should be 0)', role_comp_3_count;
    RAISE NOTICE 'role_competency_matrix with value 4: %', role_comp_4_count;
    RAISE NOTICE 'unknown_role_competency_matrix with value 3: % (should be 0)', unknown_comp_3_count;
    RAISE NOTICE 'unknown_role_competency_matrix with value 4: %', unknown_comp_4_count;
    RAISE NOTICE 'user_se_competency_survey_results with score 3: % (should be 0)', survey_3_count;
    RAISE NOTICE 'user_se_competency_survey_results with score 4: %', survey_4_count;
    RAISE NOTICE 'user_se_competency_survey_results with score 5: % (should be 0)', survey_5_count;
    RAISE NOTICE 'user_se_competency_survey_results with score 6: %', survey_6_count;
    RAISE NOTICE '=================================================================';

    IF role_comp_3_count = 0 AND unknown_comp_3_count = 0 AND survey_3_count = 0 AND survey_5_count = 0 THEN
        RAISE NOTICE '[SUCCESS] Migration completed successfully - all invalid values removed';
    ELSE
        RAISE WARNING '[ERROR] Migration incomplete - invalid values still exist!';
    END IF;
END $$;

-- =============================================================================
-- SUMMARY
-- =============================================================================

RAISE NOTICE '=================================================================';
RAISE NOTICE 'MIGRATION 010 COMPLETE';
RAISE NOTICE '=================================================================';
RAISE NOTICE 'Changes applied:';
RAISE NOTICE '1. role_competency_matrix: level 3 -> 4';
RAISE NOTICE '2. unknown_role_competency_matrix: level 3 -> 4';
RAISE NOTICE '3. user_se_competency_survey_results: score 3 -> 4, score 5 -> 6';
RAISE NOTICE '4. Stored procedures updated with correct mapping';
RAISE NOTICE '5. Constraints updated to prevent future invalid values';
RAISE NOTICE '=================================================================';
RAISE NOTICE 'Valid competency levels: 0, 1, 2, 4, 6';
RAISE NOTICE 'These align with learning objectives templates';
RAISE NOTICE '=================================================================';
