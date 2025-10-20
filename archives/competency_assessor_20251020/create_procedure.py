"""
Create the stored procedure for updating role-competency matrix
"""

from app import create_app, db
from sqlalchemy import text

def create_stored_procedure():
    """Create the update_role_competency_matrix stored procedure"""
    print("Creating stored procedure...")

    procedure_sql = """
    CREATE OR REPLACE PROCEDURE public.update_role_competency_matrix(IN _organization_id integer)
    LANGUAGE plpgsql
    AS $$
    BEGIN
        -- Step 1: Delete existing entries for the given organization_id from role_competency_matrix
        DELETE FROM public.role_competency_matrix
        WHERE organization_id = _organization_id;

        -- Step 2: Insert calculated role-competency relationships into the matrix for the given organization
        INSERT INTO public.role_competency_matrix (role_cluster_id, competency_id, role_competency_value, organization_id)
        SELECT
            rpm.role_cluster_id,
            pcm.competency_id,
            MAX(
                CASE
                    -- Multiply role_process_value and process_competency_value to get the result value
                    WHEN rpm.role_process_value * pcm.process_competency_value = 0 THEN 0
                    WHEN rpm.role_process_value * pcm.process_competency_value = 1 THEN 1
                    WHEN rpm.role_process_value * pcm.process_competency_value = 2 THEN 2
                    WHEN rpm.role_process_value * pcm.process_competency_value = 3 THEN 3
                    WHEN rpm.role_process_value * pcm.process_competency_value = 4 THEN 4
                    WHEN rpm.role_process_value * pcm.process_competency_value = 6 THEN 6
                    ELSE -100
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

        RAISE NOTICE 'Role-Competency matrix updated successfully for organization_id %', _organization_id;

    END $$;
    """

    app = create_app()
    with app.app_context():
        try:
            db.session.execute(text(procedure_sql))
            db.session.commit()
            print("[SUCCESS] Stored procedure created successfully!")
        except Exception as e:
            print(f"[ERROR] Failed to create stored procedure: {e}")
            db.session.rollback()
            raise

if __name__ == '__main__':
    create_stored_procedure()
