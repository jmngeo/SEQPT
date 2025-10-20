-- Create the stored procedure to calculate competency requirements for task-based assessments
-- This multiplies unknown_role_process values with process_competency values

CREATE OR REPLACE PROCEDURE public.update_unknown_role_competency_values(
    IN input_user_name text,
    IN input_organization_id integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- First delete any existing entries for the user and organization
    DELETE FROM unknown_role_competency_matrix
    WHERE user_name = input_user_name
      AND organization_id = input_organization_id;

    -- Insert calculated competency requirements
    INSERT INTO unknown_role_competency_matrix (user_name, competency_id, role_competency_value, organization_id)
    SELECT
        urpm.user_name::VARCHAR(50),
        pcm.competency_id,
        MAX(
            CASE
                -- Multiply role_process_value and process_competency_value
                WHEN urpm.role_process_value * pcm.process_competency_value = 0 THEN 0
                WHEN urpm.role_process_value * pcm.process_competency_value = 1 THEN 1
                WHEN urpm.role_process_value * pcm.process_competency_value = 2 THEN 2
                WHEN urpm.role_process_value * pcm.process_competency_value = 3 THEN 3
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
