-- Migration: Update role_competency_matrix to reference organization_roles
-- Date: 2025-10-29
-- Purpose: Fix foreign key constraint after organization_roles migration
-- Note: Existing data will be deleted and recalculated by stored procedure

BEGIN;

-- Step 1: Count existing entries (for logging)
DO $$
DECLARE
    old_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO old_count FROM role_competency_matrix;
    RAISE NOTICE 'Existing role_competency_matrix entries: %', old_count;
END $$;

-- Step 2: Delete all existing entries
-- They will be recalculated by update_role_competency_matrix stored procedure
DELETE FROM role_competency_matrix;

DO $$
BEGIN
    RAISE NOTICE 'Deleted all existing entries - will be recalculated by stored procedure';
END $$;

-- Step 3: Drop old foreign key constraint
ALTER TABLE role_competency_matrix
    DROP CONSTRAINT IF EXISTS fk_role_cluster;

-- Step 4: Add new foreign key constraint to reference organization_roles
-- Note: role_cluster_id column now references organization_roles.id (user-defined roles)
ALTER TABLE role_competency_matrix
    ADD CONSTRAINT role_competency_matrix_org_role_fkey
    FOREIGN KEY (role_cluster_id) REFERENCES organization_roles(id) ON DELETE CASCADE;

-- Step 5: Add comment to clarify the column meaning
COMMENT ON COLUMN role_competency_matrix.role_cluster_id IS
    'References organization_roles.id (user-defined roles), not role_cluster.id. Column name kept for backward compatibility.';

-- Step 6: Recalculate role-competency matrix for all organizations
DO $$
DECLARE
    org_record RECORD;
    total_entries INTEGER := 0;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Recalculating role-competency matrices ===';

    FOR org_record IN
        SELECT DISTINCT organization_id FROM role_process_matrix ORDER BY organization_id
    LOOP
        CALL update_role_competency_matrix(org_record.organization_id);
        RAISE NOTICE 'Recalculated for organization %', org_record.organization_id;
    END LOOP;

    SELECT COUNT(*) INTO total_entries FROM role_competency_matrix;

    RAISE NOTICE '';
    RAISE NOTICE '=== Migration Summary ===';
    RAISE NOTICE 'Updated foreign key constraint on role_competency_matrix';
    RAISE NOTICE 'Recalculated entries: %', total_entries;
    RAISE NOTICE '=== Migration Complete ===';
END $$;

COMMIT;
