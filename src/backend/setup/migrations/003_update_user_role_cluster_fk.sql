-- Migration: Update user_role_cluster to reference organization_roles
-- Date: 2025-10-30
-- Purpose: Fix foreign key constraint to support both standard and custom roles
-- Reason: user_role_cluster needs to store actual organization role selections (IDs from organization_roles),
--         not generic cluster IDs (1-14). This enables proper tracking of custom roles in assessments.
--
-- Impact: Enables Phase 2 assessments to work with both:
--         - Standard-derived roles (e.g., "End User" -> org_role_id 286 -> cluster_id 1)
--         - Custom roles (e.g., "Pepe Lolo" -> org_role_id 294 -> cluster_id NULL)

BEGIN;

-- Step 1: Check existing data
DO $$
DECLARE
    existing_count INTEGER;
    assessment_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO existing_count FROM user_role_cluster;
    SELECT COUNT(DISTINCT assessment_id) INTO assessment_count FROM user_role_cluster WHERE assessment_id IS NOT NULL;

    RAISE NOTICE '';
    RAISE NOTICE '=== Migration 003: Update user_role_cluster FK ===';
    RAISE NOTICE 'Current user_role_cluster entries: %', existing_count;
    RAISE NOTICE 'Linked assessments: %', assessment_count;

    IF existing_count > 0 THEN
        RAISE NOTICE 'WARNING: Existing data will be deleted as it references role_cluster (1-14)';
        RAISE NOTICE 'These entries are incompatible with the new organization_roles FK';
    END IF;
END $$;

-- Step 2: Delete existing entries
-- Current data references role_cluster.id (1-14) which is incompatible
-- with the new FK to organization_roles.id (286, 287, 294, etc.)
DELETE FROM user_role_cluster;

DO $$
BEGIN
    RAISE NOTICE 'Deleted all existing entries - assessments can be re-run';
END $$;

-- Step 3: Drop old foreign key constraint
ALTER TABLE user_role_cluster
    DROP CONSTRAINT IF EXISTS user_role_cluster_role_cluster_id_fkey;

DO $$
BEGIN
    RAISE NOTICE 'Dropped old FK constraint: user_role_cluster_role_cluster_id_fkey';
END $$;

-- Step 4: Add new foreign key constraint to reference organization_roles
-- Now role_cluster_id references organization_roles.id (user-defined roles)
-- This allows both standard-derived roles AND custom roles to be stored
ALTER TABLE user_role_cluster
    ADD CONSTRAINT user_role_cluster_role_cluster_id_fkey
    FOREIGN KEY (role_cluster_id) REFERENCES organization_roles(id) ON DELETE CASCADE;

DO $$
BEGIN
    RAISE NOTICE 'Added new FK constraint: user_role_cluster -> organization_roles';
END $$;

-- Step 5: Add comment to clarify the column meaning
COMMENT ON COLUMN user_role_cluster.role_cluster_id IS
    'References organization_roles.id (user-defined roles from Phase 1), not role_cluster.id. Column name kept for backward compatibility. Stores actual organization role selections for assessments.';

COMMENT ON TABLE user_role_cluster IS
    'Maps users to their selected organization roles for assessments. Links to organization_roles table which contains both standard-derived roles (with cluster mapping) and custom roles (without cluster mapping).';

-- Step 6: Summary
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Migration Summary ===';
    RAISE NOTICE 'Updated foreign key: user_role_cluster.role_cluster_id -> organization_roles.id';
    RAISE NOTICE 'Cleared old data: All entries deleted (incompatible FK)';
    RAISE NOTICE 'Impact: Phase 2 assessments now support custom AND standard roles';
    RAISE NOTICE '=== Migration Complete ===';
    RAISE NOTICE '';
END $$;

COMMIT;
