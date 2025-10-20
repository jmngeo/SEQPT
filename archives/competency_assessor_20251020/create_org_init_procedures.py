"""
Create stored procedures for initializing new organization matrices.
These procedures copy default matrix values from organization_id=1 to new organizations.
"""

from app import create_app, db
from sqlalchemy import text

def create_procedures():
    """Create stored procedures for new organization initialization"""
    app = create_app()

    with app.app_context():
        print("=" * 60)
        print("Creating organization initialization procedures...")
        print("=" * 60)

        # Procedure 1: Copy Role-Process Matrix defaults
        role_process_proc = """
        CREATE OR REPLACE PROCEDURE insert_new_org_default_role_process_matrix(_organization_id INT)
        LANGUAGE plpgsql
        AS $$
        BEGIN
            -- Insert rows into role_process_matrix copying from organization_id = 1
            INSERT INTO public.role_process_matrix (role_cluster_id, iso_process_id, role_process_value, organization_id)
            SELECT
                role_cluster_id,
                iso_process_id,
                role_process_value,
                _organization_id
            FROM public.role_process_matrix
            WHERE organization_id = 1;

            RAISE NOTICE 'Rows successfully inserted into role_process_matrix with organization_id %', _organization_id;
        END;
        $$;
        """

        # Procedure 2: Copy Role-Competency Matrix defaults
        role_competency_proc = """
        CREATE OR REPLACE PROCEDURE insert_new_org_default_role_competency_matrix(_organization_id INT)
        LANGUAGE plpgsql
        AS $$
        BEGIN
            -- Insert rows into role_competency_matrix copying from organization_id = 1
            INSERT INTO public.role_competency_matrix (role_cluster_id, competency_id, role_competency_value, organization_id)
            SELECT
                role_cluster_id,
                competency_id,
                role_competency_value,
                _organization_id
            FROM public.role_competency_matrix
            WHERE organization_id = 1;

            RAISE NOTICE 'Rows successfully inserted into role_competency_matrix with organization_id %', _organization_id;
        END;
        $$;
        """

        try:
            # Create Role-Process Matrix initialization procedure
            print("\n[1/2] Creating insert_new_org_default_role_process_matrix procedure...")
            db.session.execute(text(role_process_proc))
            db.session.commit()
            print("[OK] insert_new_org_default_role_process_matrix created successfully")

            # Create Role-Competency Matrix initialization procedure
            print("\n[2/2] Creating insert_new_org_default_role_competency_matrix procedure...")
            db.session.execute(text(role_competency_proc))
            db.session.commit()
            print("[OK] insert_new_org_default_role_competency_matrix created successfully")

            print("\n" + "=" * 60)
            print("[SUCCESS] All procedures created successfully!")
            print("=" * 60)
            print("\nNew organizations will now automatically receive:")
            print("  1. Default Role-Process Matrix values")
            print("  2. Default Role-Competency Matrix values")
            print("\nThese defaults are copied from organization_id=1")

        except Exception as e:
            print(f"\n[ERROR] Failed to create procedures: {e}")
            db.session.rollback()
            raise


if __name__ == '__main__':
    create_procedures()
