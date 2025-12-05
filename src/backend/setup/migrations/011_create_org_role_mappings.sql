-- ================================================================
-- Migration 011: Create organization_role_mappings table
-- ================================================================
--
-- Purpose:
--   Store AI-powered mappings of organization-specific roles to
--   SE-QPT role clusters.
--
-- Feature:
--   AI-Powered Role Mapping for Phase 1 Task 2
--
-- Author: SE-QPT Development Team
-- Date: 2025-11-15
--
-- ================================================================

-- Create the main table
CREATE TABLE IF NOT EXISTS organization_role_mappings (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL REFERENCES organization(id) ON DELETE CASCADE,

    -- Organization's custom role information
    org_role_title VARCHAR(255) NOT NULL,
    org_role_description TEXT,
    org_role_responsibilities TEXT, -- JSON array of responsibilities
    org_role_skills TEXT, -- JSON array of required skills

    -- Mapping to SE-QPT role cluster
    mapped_cluster_id INTEGER NOT NULL REFERENCES role_cluster(id),

    -- AI analysis metadata
    confidence_score DECIMAL(5,2) CHECK (confidence_score >= 0 AND confidence_score <= 100),
    mapping_reasoning TEXT, -- Why this cluster was selected by AI
    matched_responsibilities TEXT, -- JSON array of which responsibilities matched

    -- User validation
    user_confirmed BOOLEAN DEFAULT FALSE,
    confirmed_by INTEGER REFERENCES users(id),
    confirmed_at TIMESTAMP,

    -- Source tracking
    upload_source VARCHAR(50), -- 'manual', 'file_upload', 'api', 'ai_batch'
    upload_batch_id UUID, -- Group related uploads

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Ensure no duplicate mappings for same role to same cluster
    UNIQUE(organization_id, org_role_title, mapped_cluster_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_org_role_mappings_org_id
    ON organization_role_mappings(organization_id);

CREATE INDEX IF NOT EXISTS idx_org_role_mappings_cluster_id
    ON organization_role_mappings(mapped_cluster_id);

CREATE INDEX IF NOT EXISTS idx_org_role_mappings_batch_id
    ON organization_role_mappings(upload_batch_id);

CREATE INDEX IF NOT EXISTS idx_org_role_mappings_confirmed
    ON organization_role_mappings(user_confirmed);

CREATE INDEX IF NOT EXISTS idx_org_role_mappings_org_cluster
    ON organization_role_mappings(organization_id, mapped_cluster_id);

-- Create or update the timestamp trigger function
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger for automatic timestamp updates
DROP TRIGGER IF EXISTS update_org_role_mappings_timestamp ON organization_role_mappings;

CREATE TRIGGER update_org_role_mappings_timestamp
    BEFORE UPDATE ON organization_role_mappings
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

-- Grant permissions to seqpt_admin
GRANT SELECT, INSERT, UPDATE, DELETE ON organization_role_mappings TO seqpt_admin;
GRANT USAGE, SELECT ON SEQUENCE organization_role_mappings_id_seq TO seqpt_admin;

-- Optional: Grant read-only access to ma0349 (if needed)
-- GRANT SELECT ON organization_role_mappings TO ma0349;

-- Add helpful comments to the table and columns
COMMENT ON TABLE organization_role_mappings IS
    'Stores AI-powered mappings of organization-specific job roles to SE-QPT role clusters';

COMMENT ON COLUMN organization_role_mappings.org_role_title IS
    'Title of the role in the organization (e.g., "Senior Software Developer")';

COMMENT ON COLUMN organization_role_mappings.org_role_description IS
    'Description of what this role does in the organization';

COMMENT ON COLUMN organization_role_mappings.org_role_responsibilities IS
    'JSON array of key responsibilities for this role';

COMMENT ON COLUMN organization_role_mappings.org_role_skills IS
    'JSON array of required skills for this role';

COMMENT ON COLUMN organization_role_mappings.mapped_cluster_id IS
    'ID of the SE-QPT role cluster this role maps to';

COMMENT ON COLUMN organization_role_mappings.confidence_score IS
    'AI confidence score (0-100%) for this mapping';

COMMENT ON COLUMN organization_role_mappings.mapping_reasoning IS
    'AI-generated explanation of why this mapping was made';

COMMENT ON COLUMN organization_role_mappings.matched_responsibilities IS
    'JSON array of which specific responsibilities matched this cluster';

COMMENT ON COLUMN organization_role_mappings.user_confirmed IS
    'Whether the user has reviewed and confirmed this mapping';

COMMENT ON COLUMN organization_role_mappings.upload_batch_id IS
    'UUID to group multiple roles uploaded together';

-- Success message
DO $$
BEGIN
    RAISE NOTICE '================================================================';
    RAISE NOTICE '[SUCCESS] Migration 011 completed successfully';
    RAISE NOTICE 'Table: organization_role_mappings';
    RAISE NOTICE 'Indexes: 5 created';
    RAISE NOTICE 'Trigger: update_org_role_mappings_timestamp';
    RAISE NOTICE '================================================================';
END $$;
