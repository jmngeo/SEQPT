-- Migration: Create organization_roles table and migrate existing data
-- Date: 2025-10-29
-- Purpose: Support user-defined roles per organization with optional cluster mapping

BEGIN;

-- Step 1: Create organization_roles table
CREATE TABLE IF NOT EXISTS organization_roles (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL REFERENCES organization(id) ON DELETE CASCADE,
    role_name VARCHAR(255) NOT NULL,
    role_description TEXT,
    standard_role_cluster_id INTEGER REFERENCES role_cluster(id),
    identification_method VARCHAR(50) DEFAULT 'STANDARD',
    participating_in_training BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, role_name)
);

CREATE INDEX IF NOT EXISTS idx_org_roles_org_id ON organization_roles(organization_id);
CREATE INDEX IF NOT EXISTS idx_org_roles_cluster_id ON organization_roles(standard_role_cluster_id);

-- Step 2: Migrate existing data
-- For each organization with role_process_matrix data, create organization_roles entries
-- matching the 14 standard role clusters they're using

-- Create a temporary mapping table
CREATE TEMP TABLE org_role_id_mapping (
    organization_id INTEGER,
    old_role_cluster_id INTEGER,
    new_org_role_id INTEGER
);

-- For each organization that has matrix data, create organization_roles for the 14 standard clusters
DO $$
DECLARE
    org_record RECORD;
    role_record RECORD;
    new_role_id INTEGER;
BEGIN
    -- Loop through each organization with matrix data
    FOR org_record IN
        SELECT DISTINCT organization_id FROM role_process_matrix ORDER BY organization_id
    LOOP
        -- For each of the 14 standard role clusters used by this org
        FOR role_record IN
            SELECT DISTINCT rpm.role_cluster_id, rc.role_cluster_name, rc.role_cluster_description
            FROM role_process_matrix rpm
            JOIN role_cluster rc ON rpm.role_cluster_id = rc.id
            WHERE rpm.organization_id = org_record.organization_id
            ORDER BY rpm.role_cluster_id
        LOOP
            -- Insert into organization_roles (using cluster name as role name)
            INSERT INTO organization_roles (
                organization_id,
                role_name,
                role_description,
                standard_role_cluster_id,
                identification_method,
                participating_in_training
            ) VALUES (
                org_record.organization_id,
                role_record.role_cluster_name,  -- Use cluster name as default role name
                role_record.role_cluster_description,
                role_record.role_cluster_id,  -- Link to standard cluster
                'STANDARD',
                true
            ) RETURNING id INTO new_role_id;

            -- Store mapping for later update
            INSERT INTO org_role_id_mapping (organization_id, old_role_cluster_id, new_org_role_id)
            VALUES (org_record.organization_id, role_record.role_cluster_id, new_role_id);

            RAISE NOTICE 'Created org_role % for org % (cluster %)', new_role_id, org_record.organization_id, role_record.role_cluster_id;
        END LOOP;
    END LOOP;
END $$;

-- Step 3: Add a temporary column to role_process_matrix for new IDs
ALTER TABLE role_process_matrix ADD COLUMN IF NOT EXISTS temp_org_role_id INTEGER;

-- Step 4: Update role_process_matrix with new organization_roles IDs
UPDATE role_process_matrix rpm
SET temp_org_role_id = mapping.new_org_role_id
FROM org_role_id_mapping mapping
WHERE rpm.organization_id = mapping.organization_id
  AND rpm.role_cluster_id = mapping.old_role_cluster_id;

-- Step 5: Verify all rows were updated
DO $$
DECLARE
    null_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO null_count FROM role_process_matrix WHERE temp_org_role_id IS NULL;
    IF null_count > 0 THEN
        RAISE EXCEPTION 'Migration failed: % rows have NULL temp_org_role_id', null_count;
    END IF;
    RAISE NOTICE '[OK] All % rows successfully mapped to organization_roles',
        (SELECT COUNT(*) FROM role_process_matrix);
END $$;

-- Step 6: Drop old foreign key constraint
ALTER TABLE role_process_matrix DROP CONSTRAINT IF EXISTS role_process_matrix_role_cluster_id_fkey;

-- Step 7: Copy new IDs to role_cluster_id column
UPDATE role_process_matrix SET role_cluster_id = temp_org_role_id;

-- Step 8: Add new foreign key constraint
ALTER TABLE role_process_matrix
    ADD CONSTRAINT role_process_matrix_org_role_fkey
    FOREIGN KEY (role_cluster_id) REFERENCES organization_roles(id) ON DELETE CASCADE;

-- Step 9: Update unique constraint
ALTER TABLE role_process_matrix DROP CONSTRAINT IF EXISTS role_process_matrix_unique;
ALTER TABLE role_process_matrix
    ADD CONSTRAINT role_process_matrix_unique
    UNIQUE (organization_id, role_cluster_id, iso_process_id);

-- Step 10: Add comment to clarify column meaning
COMMENT ON COLUMN role_process_matrix.role_cluster_id IS
    'References organization_roles.id (user-defined roles). Column name kept for backward compatibility.';

-- Step 11: Drop temporary column
ALTER TABLE role_process_matrix DROP COLUMN temp_org_role_id;

-- Step 12: Show summary
DO $$
DECLARE
    org_count INTEGER;
    role_count INTEGER;
    matrix_count INTEGER;
BEGIN
    SELECT COUNT(DISTINCT organization_id) INTO org_count FROM organization_roles;
    SELECT COUNT(*) INTO role_count FROM organization_roles;
    SELECT COUNT(*) INTO matrix_count FROM role_process_matrix;

    RAISE NOTICE '';
    RAISE NOTICE '=== Migration Summary ===';
    RAISE NOTICE 'Organizations with roles: %', org_count;
    RAISE NOTICE 'Total organization_roles created: %', role_count;
    RAISE NOTICE 'Total role_process_matrix entries migrated: %', matrix_count;
    RAISE NOTICE '=== Migration Complete ===';
END $$;

COMMIT;
