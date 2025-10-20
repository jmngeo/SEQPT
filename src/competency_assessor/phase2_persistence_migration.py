"""
Phase 2 Persistence Migration
==============================
Adds complete persistence layer for Phase 2 competency assessments.

CHANGES:
1. Add admin_user_id to app_user (links AppUser to AdminUser)
2. Create competency_assessment table (tracks assessment instances)
3. Add assessment_id to user_se_competency_survey_results
4. Add assessment_id to user_competency_survey_feedback
5. Create indexes for performance
6. Backfill admin_user_id where possible

BACKUP YOUR DATABASE BEFORE RUNNING!
"""

from app import create_app, db
from sqlalchemy import text

def run_migration():
    """Execute the Phase 2 persistence migration"""
    app = create_app()

    with app.app_context():
        print("=" * 80)
        print("PHASE 2 PERSISTENCE MIGRATION")
        print("=" * 80)

        # Migration scripts
        migrations = []

        # 1. Add admin_user_id to app_user
        migrations.append({
            'name': 'Add admin_user_id to app_user',
            'check': """
                SELECT column_name
                FROM information_schema.columns
                WHERE table_name='app_user' AND column_name='admin_user_id'
            """,
            'sql': """
                ALTER TABLE app_user ADD COLUMN admin_user_id INTEGER;
                ALTER TABLE app_user ADD CONSTRAINT fk_app_user_admin
                    FOREIGN KEY (admin_user_id) REFERENCES admin_user(id) ON DELETE SET NULL;
                CREATE INDEX idx_app_user_admin_user_id ON app_user(admin_user_id);
            """
        })

        # 2. Backfill admin_user_id (best effort)
        migrations.append({
            'name': 'Backfill admin_user_id in app_user',
            'check': None,  # Always run if admin_user_id exists
            'sql': """
                UPDATE app_user
                SET admin_user_id = (
                    SELECT id FROM admin_user
                    WHERE admin_user.username = app_user.username
                    AND admin_user.organization_id = app_user.organization_id
                    LIMIT 1
                )
                WHERE admin_user_id IS NULL
                AND EXISTS (
                    SELECT 1 FROM admin_user
                    WHERE admin_user.username = app_user.username
                    AND admin_user.organization_id = app_user.organization_id
                );
            """
        })

        # 3. Create competency_assessment table
        migrations.append({
            'name': 'Create competency_assessment table',
            'check': """
                SELECT table_name
                FROM information_schema.tables
                WHERE table_name='competency_assessment'
            """,
            'sql': """
                CREATE TABLE competency_assessment (
                    id SERIAL PRIMARY KEY,
                    admin_user_id INTEGER NOT NULL REFERENCES admin_user(id) ON DELETE CASCADE,
                    app_user_id INTEGER REFERENCES app_user(id) ON DELETE SET NULL,
                    organization_id INTEGER NOT NULL REFERENCES organization(id) ON DELETE CASCADE,

                    -- Assessment metadata
                    assessment_type VARCHAR(50) NOT NULL,  -- 'known_roles', 'unknown_roles', 'all_roles'
                    assessment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
                    status VARCHAR(50) DEFAULT 'in_progress' NOT NULL,  -- 'in_progress', 'completed', 'abandoned'

                    -- Phase 2 Step 3: Company Context (Q5/Q6)
                    company_context JSONB,
                    context_type VARCHAR(50),  -- 'extended_pmt', 'basic', 'dual'

                    -- Phase 2 Step 4: Learning Objectives
                    learning_objectives JSONB,
                    objectives_generated_at TIMESTAMP,

                    -- Role/task metadata
                    selected_roles JSONB,  -- For known_roles
                    matched_roles JSONB,   -- For unknown_roles/all_roles
                    task_inputs JSONB,     -- For unknown_roles

                    -- Summary metrics
                    overall_score FLOAT,
                    completed_at TIMESTAMP,

                    -- Audit fields
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );

                CREATE INDEX idx_comp_assess_admin_user ON competency_assessment(admin_user_id);
                CREATE INDEX idx_comp_assess_org ON competency_assessment(organization_id);
                CREATE INDEX idx_comp_assess_date ON competency_assessment(assessment_date DESC);
                CREATE INDEX idx_comp_assess_status ON competency_assessment(status);
            """
        })

        # 4. Add assessment_id to user_se_competency_survey_results
        migrations.append({
            'name': 'Add assessment_id to user_se_competency_survey_results',
            'check': """
                SELECT column_name
                FROM information_schema.columns
                WHERE table_name='user_se_competency_survey_results' AND column_name='assessment_id'
            """,
            'sql': """
                ALTER TABLE user_se_competency_survey_results ADD COLUMN assessment_id INTEGER;
                ALTER TABLE user_se_competency_survey_results
                    ADD CONSTRAINT fk_survey_results_assessment
                    FOREIGN KEY (assessment_id) REFERENCES competency_assessment(id) ON DELETE CASCADE;
                CREATE INDEX idx_survey_results_assessment ON user_se_competency_survey_results(assessment_id);
            """
        })

        # 5. Add assessment_id to user_competency_survey_feedback
        migrations.append({
            'name': 'Add assessment_id to user_competency_survey_feedback',
            'check': """
                SELECT column_name
                FROM information_schema.columns
                WHERE table_name='user_competency_survey_feedback' AND column_name='assessment_id'
            """,
            'sql': """
                ALTER TABLE user_competency_survey_feedback ADD COLUMN assessment_id INTEGER;
                ALTER TABLE user_competency_survey_feedback
                    ADD CONSTRAINT fk_survey_feedback_assessment
                    FOREIGN KEY (assessment_id) REFERENCES competency_assessment(id) ON DELETE CASCADE;
                CREATE INDEX idx_survey_feedback_assessment ON user_competency_survey_feedback(assessment_id);
            """
        })

        # Execute migrations
        for migration in migrations:
            print(f"\n[MIGRATION] {migration['name']}")

            try:
                # Check if already applied
                if migration['check']:
                    result = db.session.execute(text(migration['check'])).fetchone()
                    if result:
                        print(f"[SKIP] Already applied")
                        continue

                # Execute migration
                print(f"[RUNNING] Executing SQL...")
                db.session.execute(text(migration['sql']))
                db.session.commit()
                print(f"[OK] Completed successfully")

            except Exception as e:
                print(f"[ERROR] Failed: {str(e)}")
                db.session.rollback()

                # Ask if we should continue
                response = input("Continue with remaining migrations? (y/n): ")
                if response.lower() != 'y':
                    print("\n[ABORTED] Migration stopped by user")
                    return False

        print("\n" + "=" * 80)
        print("MIGRATION COMPLETED")
        print("=" * 80)
        print("\nSummary:")
        print("- app_user.admin_user_id: Links AppUser to AdminUser")
        print("- competency_assessment: Tracks assessment instances with all Phase 2 data")
        print("- user_se_competency_survey_results.assessment_id: Links scores to assessments")
        print("- user_competency_survey_feedback.assessment_id: Links feedback to assessments")
        print("\nNext Steps:")
        print("1. Update models.py to add CompetencyAssessment model")
        print("2. Update routes.py to create assessment instances")
        print("3. Create frontend components for assessment history")
        print("\nSee PHASE2_ANALYSIS_AND_UX_FIXES.md for complete implementation guide")

        return True


if __name__ == '__main__':
    print("\n" + "=" * 80)
    print("IMPORTANT: BACKUP YOUR DATABASE BEFORE PROCEEDING!")
    print("=" * 80)
    print("\nThis migration will:")
    print("1. Add admin_user_id to app_user table")
    print("2. Create competency_assessment table")
    print("3. Add assessment_id to survey results and feedback tables")
    print("4. Create necessary indexes")
    print("\nDatabase: postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment")

    response = input("\nProceed with migration? (yes/no): ")

    if response.lower() == 'yes':
        success = run_migration()
        if success:
            print("\n[SUCCESS] Migration completed successfully!")
        else:
            print("\n[FAILED] Migration encountered errors")
    else:
        print("\n[CANCELLED] Migration cancelled by user")
