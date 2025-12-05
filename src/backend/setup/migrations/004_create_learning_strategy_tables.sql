-- Migration 004: Create Learning Strategy Tables for Phase 2
-- Created: 2025-11-04
-- Purpose: Create learning_strategy and strategy_competency tables for Phase 2 Role-Based Pathway Algorithm

-- ============================================================================
-- Table: learning_strategy
-- Stores learning strategies defined by organizations for Phase 2
-- ============================================================================

CREATE TABLE IF NOT EXISTS learning_strategy (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL,
    strategy_name VARCHAR(255) NOT NULL,
    strategy_description TEXT,
    selected BOOLEAN DEFAULT FALSE,
    priority INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Foreign key constraint
    CONSTRAINT fk_learning_strategy_organization
        FOREIGN KEY (organization_id)
        REFERENCES organization(id)
        ON DELETE CASCADE,

    -- Unique constraint: one strategy name per organization
    CONSTRAINT learning_strategy_org_name_unique
        UNIQUE (organization_id, strategy_name)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_learning_strategy_org_id ON learning_strategy(organization_id);
CREATE INDEX IF NOT EXISTS idx_learning_strategy_selected ON learning_strategy(organization_id, selected);

-- ============================================================================
-- Table: strategy_competency
-- Junction table mapping learning strategies to competencies with target levels
-- ============================================================================

CREATE TABLE IF NOT EXISTS strategy_competency (
    id SERIAL PRIMARY KEY,
    strategy_id INTEGER NOT NULL,
    competency_id INTEGER NOT NULL,
    target_level INTEGER NOT NULL,

    -- Foreign key constraints
    CONSTRAINT fk_strategy_competency_strategy
        FOREIGN KEY (strategy_id)
        REFERENCES learning_strategy(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_strategy_competency_competency
        FOREIGN KEY (competency_id)
        REFERENCES competency(id)
        ON DELETE CASCADE,

    -- Unique constraint: one target level per strategy-competency pair
    CONSTRAINT strategy_competency_unique
        UNIQUE (strategy_id, competency_id),

    -- Check constraint: target_level must be valid competency level
    CONSTRAINT strategy_competency_target_level_check
        CHECK (target_level IN (0, 1, 2, 4, 6))
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_strategy_competency_strategy_id ON strategy_competency(strategy_id);
CREATE INDEX IF NOT EXISTS idx_strategy_competency_competency_id ON strategy_competency(competency_id);

-- ============================================================================
-- Comments for documentation
-- ============================================================================

COMMENT ON TABLE learning_strategy IS 'Learning strategies defined by organizations for Phase 2 competency training';
COMMENT ON COLUMN learning_strategy.selected IS 'Whether this strategy is currently selected by the organization';
COMMENT ON COLUMN learning_strategy.priority IS 'Priority order for strategy execution (1 = highest)';

COMMENT ON TABLE strategy_competency IS 'Junction table mapping learning strategies to competencies with target proficiency levels';
COMMENT ON COLUMN strategy_competency.target_level IS 'Target competency level: 0=not covered, 1=awareness, 2=supervised, 4=independent, 6=expert';

-- ============================================================================
-- Verification queries
-- ============================================================================

-- Verify tables were created
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'learning_strategy') THEN
        RAISE NOTICE '[OK] learning_strategy table created successfully';
    ELSE
        RAISE EXCEPTION '[ERROR] learning_strategy table creation failed';
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'strategy_competency') THEN
        RAISE NOTICE '[OK] strategy_competency table created successfully';
    ELSE
        RAISE EXCEPTION '[ERROR] strategy_competency table creation failed';
    END IF;
END $$;
