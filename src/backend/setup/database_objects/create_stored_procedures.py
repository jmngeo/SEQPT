"""
Create stored procedures for matrix operations from Derik's system
"""

import os
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app import create_app
from models import db
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("=" * 80)
    print("CREATING STORED PROCEDURES FOR MATRIX OPERATIONS")
    print("=" * 80)

    # 1. Create procedure to copy role_process_matrix for new organizations
    print("\n[1/3] Creating insert_new_org_default_role_process_matrix...")
    db.session.execute(text("""
        CREATE OR REPLACE PROCEDURE public.insert_new_org_default_role_process_matrix(
            IN _organization_id integer
        )
        LANGUAGE plpgsql
        AS $$
        BEGIN
            -- Insert rows into role_process_matrix where organization_id is 1
            INSERT INTO public.role_process_matrix (role_cluster_id, iso_process_id, role_process_value, organization_id)
            SELECT
                role_cluster_id,
                iso_process_id,
                role_process_value,
                _organization_id  -- Use the new organization_id
            FROM public.role_process_matrix
            WHERE organization_id = 1;

            RAISE NOTICE 'Rows successfully inserted into role_process_matrix with organization_id %', _organization_id;
        END;
        $$;
    """))
    print("[OK] Created insert_new_org_default_role_process_matrix")

    # 2. Create procedure to calculate role_competency_matrix from role_process + process_competency
    print("\n[2/3] Creating update_role_competency_matrix (with org_id parameter)...")
    db.session.execute(text("""
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
                        WHEN rpm.role_process_value * pcm.process_competency_value = 3 THEN 3
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
    """))
    print("[OK] Created update_role_competency_matrix")

    # 3. Create procedure to copy role_competency_matrix (for copying defaults)
    print("\n[3/3] Creating insert_new_org_default_role_competency_matrix...")
    db.session.execute(text("""
        CREATE OR REPLACE PROCEDURE public.insert_new_org_default_role_competency_matrix(
            IN _organization_id integer
        )
        LANGUAGE plpgsql
        AS $$
        BEGIN
            -- This copies pre-existing role-competency data from org_id=1
            -- Note: Normally you would call update_role_competency_matrix instead
            -- to calculate from role_process + process_competency matrices
            INSERT INTO public.role_competency_matrix (role_cluster_id, competency_id, role_competency_value, organization_id)
            SELECT
                role_cluster_id,
                competency_id,
                role_competency_value,
                _organization_id
            FROM public.role_competency_matrix
            WHERE organization_id = 1;

            RAISE NOTICE 'Rows copied into role_competency_matrix with organization_id %', _organization_id;
        END;
        $$;
    """))
    print("[OK] Created insert_new_org_default_role_competency_matrix")

    # 4. Create procedure to calculate unknown_role_competency_matrix (for task-based assessments)
    print("\n[4/5] Creating update_unknown_role_competency_values...")
    db.session.execute(text("""
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
    """))
    print("[OK] Created update_unknown_role_competency_values")

    db.session.commit()

    # Verify the procedures were created
    print("\n[5/5] Verifying stored procedures...")
    result = db.session.execute(text("""
        SELECT proname, prokind
        FROM pg_proc
        WHERE proname LIKE '%org_default%' OR proname LIKE '%update%competency%'
        ORDER BY proname;
    """)).fetchall()

    for name, kind in result:
        kind_str = "procedure" if kind == 'p' else "function"
        print(f"  [OK] {name} ({kind_str})")

    print("\n" + "=" * 80)
    print("STORED PROCEDURES CREATED SUCCESSFULLY")
    print("=" * 80)
    print("\nKey procedures:")
    print("  1. insert_new_org_default_role_process_matrix - Copies role-process matrix")
    print("  2. update_role_competency_matrix - CALCULATES role-competency from matrices")
    print("  3. insert_new_org_default_role_competency_matrix - Copies role-competency matrix")
    print("  4. update_unknown_role_competency_values - Calculates competencies for task-based users")
    print("\nImportant:")
    print("  - Procedure #2: Called when role_process_matrix or process_competency_matrix is updated")
    print("  - Procedure #4: Called after /findProcesses to convert process involvement to competencies")
