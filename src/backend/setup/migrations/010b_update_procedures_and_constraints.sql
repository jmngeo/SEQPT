-- Migration 010b: Update Stored Procedures and Constraints
-- This must be run with postgres superuser account
-- Requires: Migration 010a (data migration) to be completed first

-- =============================================================================
-- Update Stored Procedures
-- =============================================================================

-- 1. Update update_role_competency_matrix procedure
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

-- 2. Update update_unknown_role_competency_values procedure
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

-- =============================================================================
-- Update Constraints
-- =============================================================================

-- Update role_competency_matrix constraint to exclude level 3
ALTER TABLE role_competency_matrix
    DROP CONSTRAINT IF EXISTS role_competency_matrix_role_competency_value_check;

ALTER TABLE role_competency_matrix
    ADD CONSTRAINT role_competency_matrix_role_competency_value_check
    CHECK (role_competency_value = ANY (ARRAY[-100, 0, 1, 2, 4, 6]));

-- Success message
SELECT '[SUCCESS] Stored procedures and constraints updated successfully' as status;
