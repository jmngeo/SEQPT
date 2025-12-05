-- Migration 005: Create PMT Context Table for Phase 2 Task 3
-- Created: 2025-11-04
-- Purpose: Store organization-specific Processes, Methods, Tools context for deep customization

-- ============================================================================
-- Table: organization_pmt_context
-- Stores company-specific PMT (Processes, Methods, Tools) context
-- Used for deep customization of learning objectives for specific strategies
-- ============================================================================

CREATE TABLE IF NOT EXISTS organization_pmt_context (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL,
    processes TEXT,
    methods TEXT,
    tools TEXT,
    industry TEXT,
    additional_context TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Foreign key constraint
    CONSTRAINT fk_pmt_context_organization
        FOREIGN KEY (organization_id)
        REFERENCES organization(id)
        ON DELETE CASCADE,

    -- Unique constraint: one PMT context per organization
    CONSTRAINT pmt_context_org_unique
        UNIQUE (organization_id)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_pmt_context_org_id ON organization_pmt_context(organization_id);

-- ============================================================================
-- Trigger: Update updated_at timestamp
-- ============================================================================

CREATE OR REPLACE FUNCTION update_pmt_context_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_pmt_context_timestamp
    BEFORE UPDATE ON organization_pmt_context
    FOR EACH ROW
    EXECUTE FUNCTION update_pmt_context_timestamp();

-- ============================================================================
-- Comments for documentation
-- ============================================================================

COMMENT ON TABLE organization_pmt_context IS 'Organization-specific Processes, Methods, Tools context for deep customization of learning objectives';
COMMENT ON COLUMN organization_pmt_context.processes IS 'SE processes used (e.g., ISO 26262, V-model, Agile)';
COMMENT ON COLUMN organization_pmt_context.methods IS 'Methods employed (e.g., Requirements traceability, Trade-off analysis)';
COMMENT ON COLUMN organization_pmt_context.tools IS 'Tool landscape (e.g., DOORS, JIRA, SysML tools)';
COMMENT ON COLUMN organization_pmt_context.industry IS 'Industry context (e.g., Automotive, Medical devices, Aerospace)';
COMMENT ON COLUMN organization_pmt_context.additional_context IS 'Any other relevant company-specific information';

-- ============================================================================
-- Verification queries
-- ============================================================================

-- Verify table was created
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'organization_pmt_context') THEN
        RAISE NOTICE '[OK] organization_pmt_context table created successfully';
    ELSE
        RAISE EXCEPTION '[ERROR] organization_pmt_context table creation failed';
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'trigger_update_pmt_context_timestamp') THEN
        RAISE NOTICE '[OK] PMT context timestamp trigger created successfully';
    ELSE
        RAISE EXCEPTION '[ERROR] PMT context timestamp trigger creation failed';
    END IF;
END $$;

-- ============================================================================
-- Sample PMT context for testing (Organization 28)
-- ============================================================================

-- Example PMT context for a typical automotive organization
INSERT INTO organization_pmt_context (
    organization_id,
    processes,
    methods,
    tools,
    industry,
    additional_context
) VALUES (
    28,
    'ISO 26262 for automotive safety, V-model for system development, Requirements engineering process (ISO 29148)',
    'Agile with 2-week sprints, Requirements traceability, Trade-off analysis, FMEA for safety analysis',
    'DOORS for requirements management, JIRA for project tracking, Enterprise Architect for SysML modeling, Confluence for documentation',
    'Automotive embedded systems - ADAS and autonomous driving',
    'Focus on functional safety and ASIL-D compliance. Strong emphasis on verification and validation activities.'
)
ON CONFLICT (organization_id) DO NOTHING;

-- Verify sample data
SELECT
    'Sample PMT context inserted for org ' || organization_id as status,
    'Tools: ' || SUBSTRING(tools, 1, 50) || '...' as sample
FROM organization_pmt_context
WHERE organization_id = 28;
