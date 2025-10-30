-- Migration: Create organization_roles table for user-defined roles
-- Date: 2025-10-29
-- Purpose: Allow each organization to define their own roles (e.g., "Senior Developer", "Data Analyst")
--          These roles can optionally map to standard role clusters or be completely custom.

-- Step 1: Create organization_roles table
CREATE TABLE IF NOT EXISTS organization_roles (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL REFERENCES organization(id) ON DELETE CASCADE,
    role_name VARCHAR(255) NOT NULL,  -- User-defined role name (e.g., "Senior Software Engineer")
    role_description TEXT,  -- Optional description for custom roles
    standard_role_cluster_id INTEGER REFERENCES role_cluster(id),  -- NULL for custom roles, 1-14 for standard
    identification_method VARCHAR(50) DEFAULT 'STANDARD',  -- 'STANDARD' or 'CUSTOM'
    participating_in_training BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Ensure unique role names per organization
    UNIQUE(organization_id, role_name)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_org_roles_org_id ON organization_roles(organization_id);
CREATE INDEX IF NOT EXISTS idx_org_roles_cluster_id ON organization_roles(standard_role_cluster_id);

-- Step 2: Drop existing foreign key constraint on role_process_matrix
ALTER TABLE role_process_matrix
    DROP CONSTRAINT IF EXISTS role_process_matrix_role_cluster_id_fkey;

-- Step 3: Add new foreign key constraint to reference organization_roles
-- Note: We keep the column name as "role_cluster_id" for backward compatibility,
--       but it now references organization_roles.id instead of role_cluster.id
ALTER TABLE role_process_matrix
    ADD CONSTRAINT role_process_matrix_org_role_fkey
    FOREIGN KEY (role_cluster_id) REFERENCES organization_roles(id) ON DELETE CASCADE;

-- Step 4: Add comment to clarify the column meaning
COMMENT ON COLUMN role_process_matrix.role_cluster_id IS
    'References organization_roles.id (user-defined roles), not role_cluster.id. Column name kept for backward compatibility.';

-- Step 5: Update unique constraint to use correct fields
ALTER TABLE role_process_matrix
    DROP CONSTRAINT IF EXISTS role_process_matrix_unique;

ALTER TABLE role_process_matrix
    ADD CONSTRAINT role_process_matrix_unique
    UNIQUE (organization_id, role_cluster_id, iso_process_id);

COMMIT;
