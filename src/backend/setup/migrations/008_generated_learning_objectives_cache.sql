-- Migration 008: Generated Learning Objectives Cache
-- Purpose: Store and cache generated learning objectives to avoid regeneration
-- Date: 2025-11-08

-- Table: generated_learning_objectives
-- Stores cached learning objectives with input hash for invalidation
CREATE TABLE IF NOT EXISTS generated_learning_objectives (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL REFERENCES organization(id) ON DELETE CASCADE,

    -- Pathway type
    pathway VARCHAR(20) NOT NULL CHECK (pathway IN ('TASK_BASED', 'ROLE_BASED')),

    -- Full JSON output from algorithm
    objectives_data JSONB NOT NULL,

    -- Metadata
    generated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    generated_by_user_id INTEGER REFERENCES new_survey_user(id) ON DELETE SET NULL,

    -- Input snapshot (to detect when regeneration is needed)
    input_hash VARCHAR(64) NOT NULL,  -- SHA-256 hash of: assessments + strategies + PMT + maturity

    -- Validation results (for quick access)
    validation_status VARCHAR(20),  -- 'EXCELLENT', 'GOOD', 'ACCEPTABLE', 'INADEQUATE', 'CRITICAL'
    gap_percentage FLOAT,

    -- Ensure only one active cache per organization
    CONSTRAINT unique_org_cache UNIQUE (organization_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_generated_objectives_org ON generated_learning_objectives(organization_id);
CREATE INDEX IF NOT EXISTS idx_generated_objectives_timestamp ON generated_learning_objectives(generated_at DESC);
CREATE INDEX IF NOT EXISTS idx_generated_objectives_hash ON generated_learning_objectives(input_hash);

-- Comments
COMMENT ON TABLE generated_learning_objectives IS 'Caches generated learning objectives to avoid expensive regeneration';
COMMENT ON COLUMN generated_learning_objectives.objectives_data IS 'Full JSON output from generate_learning_objectives()';
COMMENT ON COLUMN generated_learning_objectives.input_hash IS 'SHA-256 hash of inputs (assessments, strategies, PMT, maturity) for cache invalidation';
COMMENT ON COLUMN generated_learning_objectives.validation_status IS 'Quick access to validation status without parsing JSON';
COMMENT ON COLUMN generated_learning_objectives.gap_percentage IS 'Quick access to gap percentage for dashboard displays';

-- Success message
DO $$
BEGIN
    RAISE NOTICE '[Migration 008] Generated learning objectives cache table created successfully';
END $$;
