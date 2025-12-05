-- =========================================================
-- MIGRATION 006: Global Strategy Templates Architecture
-- =========================================================
-- Date: November 6, 2025
-- Purpose: Create global strategy template system to eliminate data duplication
--
-- Changes:
-- 1. Create strategy_template table (global, shared across orgs)
-- 2. Create strategy_template_competency table (single source of truth)
-- 3. Add strategy_template_id to learning_strategy
-- 4. Migrate existing data to new architecture
-- 5. Keep old strategy_competency for backward compatibility (temporary)
-- =========================================================

BEGIN;

-- ===================
-- STEP 1: CREATE NEW TABLES
-- ===================

-- Global strategy templates (one per strategy type, shared across all orgs)
CREATE TABLE IF NOT EXISTS strategy_template (
    id SERIAL PRIMARY KEY,
    strategy_name VARCHAR(255) UNIQUE NOT NULL,
    strategy_description TEXT,
    requires_pmt_context BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE strategy_template IS 'Global learning strategy templates shared across all organizations';
COMMENT ON COLUMN strategy_template.strategy_name IS 'Canonical strategy name (e.g., "Common basic understanding")';
COMMENT ON COLUMN strategy_template.requires_pmt_context IS 'TRUE for strategies requiring PMT context (Needs-based, Continuous support)';
COMMENT ON COLUMN strategy_template.is_active IS 'Allow deprecation without deletion';

-- Competency targets for each strategy template
CREATE TABLE IF NOT EXISTS strategy_template_competency (
    id SERIAL PRIMARY KEY,
    strategy_template_id INTEGER NOT NULL REFERENCES strategy_template(id) ON DELETE CASCADE,
    competency_id INTEGER NOT NULL REFERENCES competency(id) ON DELETE CASCADE,
    target_level INTEGER NOT NULL CHECK (target_level BETWEEN 1 AND 6),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(strategy_template_id, competency_id)
);

COMMENT ON TABLE strategy_template_competency IS 'Competency target levels for each strategy template';
CREATE INDEX idx_strategy_template_competency_template ON strategy_template_competency(strategy_template_id);
CREATE INDEX idx_strategy_template_competency_competency ON strategy_template_competency(competency_id);

-- ===================
-- STEP 2: ADD NEW COLUMN TO learning_strategy
-- ===================

-- Add strategy_template_id to link to template
ALTER TABLE learning_strategy ADD COLUMN IF NOT EXISTS strategy_template_id INTEGER REFERENCES strategy_template(id);

COMMENT ON COLUMN learning_strategy.strategy_template_id IS 'Links to global strategy template (replaces per-org strategy definitions)';

-- ===================
-- STEP 3: POPULATE STRATEGY TEMPLATES
-- ===================

-- Insert the 7 canonical learning strategies
INSERT INTO strategy_template (strategy_name, strategy_description, requires_pmt_context, is_active) VALUES
    ('Common basic understanding', 'Foundational SE knowledge for all team members to ensure common understanding', FALSE, TRUE),
    ('SE for managers', 'Management-focused SE training for leaders and decision-makers', FALSE, TRUE),
    ('Orientation in pilot project', 'Hands-on learning through participation in a pilot SE project', FALSE, TRUE),
    ('Needs-based, project-oriented training', 'Task-specific, on-demand training tailored to project needs', TRUE, TRUE),
    ('Continuous support', 'Ongoing mentoring, coaching, and support to reinforce SE practices', TRUE, TRUE),
    ('Train the trainer', 'Prepare internal SE trainers to propagate knowledge within the organization', FALSE, TRUE),
    ('Certification', 'Formal certification programs to validate SE competencies and expertise', FALSE, TRUE)
ON CONFLICT (strategy_name) DO NOTHING;

-- ===================
-- STEP 4: POPULATE STRATEGY TEMPLATE COMPETENCIES
-- ===================

-- Use org 28 (golden reference) to populate template competencies
-- Strategy 1: Common basic understanding (from org 28 ID 13)
INSERT INTO strategy_template_competency (strategy_template_id, competency_id, target_level)
SELECT
    (SELECT id FROM strategy_template WHERE strategy_name = 'Common basic understanding'),
    sc.competency_id,
    sc.target_level
FROM strategy_competency sc
WHERE sc.strategy_id = 13  -- Org 28's "Common Basic Understanding"
ON CONFLICT (strategy_template_id, competency_id) DO NOTHING;

-- Strategy 2: SE for managers (from org 28 ID 14)
INSERT INTO strategy_template_competency (strategy_template_id, competency_id, target_level)
SELECT
    (SELECT id FROM strategy_template WHERE strategy_name = 'SE for managers'),
    sc.competency_id,
    sc.target_level
FROM strategy_competency sc
WHERE sc.strategy_id = 14  -- Org 28's "SE for Managers"
ON CONFLICT (strategy_template_id, competency_id) DO NOTHING;

-- Strategy 3: Orientation in pilot project (from org 28 ID 16)
INSERT INTO strategy_template_competency (strategy_template_id, competency_id, target_level)
SELECT
    (SELECT id FROM strategy_template WHERE strategy_name = 'Orientation in pilot project'),
    sc.competency_id,
    sc.target_level
FROM strategy_competency sc
WHERE sc.strategy_id = 16  -- Org 28's "Orientation in Pilot Project"
ON CONFLICT (strategy_template_id, competency_id) DO NOTHING;

-- Strategy 4: Needs-based, project-oriented training (from org 28 ID 12)
INSERT INTO strategy_template_competency (strategy_template_id, competency_id, target_level)
SELECT
    (SELECT id FROM strategy_template WHERE strategy_name = 'Needs-based, project-oriented training'),
    sc.competency_id,
    sc.target_level
FROM strategy_competency sc
WHERE sc.strategy_id = 12  -- Org 28's "Needs-based Project-oriented Training"
ON CONFLICT (strategy_template_id, competency_id) DO NOTHING;

-- Strategy 5: Continuous support (from org 28 ID 18)
INSERT INTO strategy_template_competency (strategy_template_id, competency_id, target_level)
SELECT
    (SELECT id FROM strategy_template WHERE strategy_name = 'Continuous support'),
    sc.competency_id,
    sc.target_level
FROM strategy_competency sc
WHERE sc.strategy_id = 18  -- Org 28's "Continuous Support"
ON CONFLICT (strategy_template_id, competency_id) DO NOTHING;

-- Strategy 6: Train the trainer (from org 28 ID 21)
INSERT INTO strategy_template_competency (strategy_template_id, competency_id, target_level)
SELECT
    (SELECT id FROM strategy_template WHERE strategy_name = 'Train the trainer'),
    sc.competency_id,
    sc.target_level
FROM strategy_competency sc
WHERE sc.strategy_id = 21  -- Org 28's "Train the SE-Trainer"
ON CONFLICT (strategy_template_id, competency_id) DO NOTHING;

-- Strategy 7: Certification (from org 28 ID 17)
INSERT INTO strategy_template_competency (strategy_template_id, competency_id, target_level)
SELECT
    (SELECT id FROM strategy_template WHERE strategy_name = 'Certification'),
    sc.competency_id,
    sc.target_level
FROM strategy_competency sc
WHERE sc.strategy_id = 17  -- Org 28's "Certification"
ON CONFLICT (strategy_template_id, competency_id) DO NOTHING;

-- ===================
-- STEP 5: MIGRATE EXISTING learning_strategy RECORDS
-- ===================

-- First, delete duplicate "Train the Trainer" (ID 19) from org 28 - it's NOT selected
-- ID 21 "Train the SE-Trainer" is selected and will be kept
DELETE FROM learning_strategy WHERE id = 19 AND organization_id = 28;

-- Link org 28 strategies to templates
UPDATE learning_strategy SET strategy_template_id = (SELECT id FROM strategy_template WHERE strategy_name = 'Needs-based, project-oriented training')
WHERE id = 12 AND organization_id = 28;

UPDATE learning_strategy SET strategy_template_id = (SELECT id FROM strategy_template WHERE strategy_name = 'Common basic understanding')
WHERE id = 13 AND organization_id = 28;

UPDATE learning_strategy SET strategy_template_id = (SELECT id FROM strategy_template WHERE strategy_name = 'SE for managers')
WHERE id = 14 AND organization_id = 28;

UPDATE learning_strategy SET strategy_template_id = (SELECT id FROM strategy_template WHERE strategy_name = 'Orientation in pilot project')
WHERE id = 16 AND organization_id = 28;

UPDATE learning_strategy SET strategy_template_id = (SELECT id FROM strategy_template WHERE strategy_name = 'Certification')
WHERE id = 17 AND organization_id = 28;

UPDATE learning_strategy SET strategy_template_id = (SELECT id FROM strategy_template WHERE strategy_name = 'Continuous support')
WHERE id = 18 AND organization_id = 28;

-- ID 21 "Train the SE-Trainer" (selected) - link to "Train the trainer" template
UPDATE learning_strategy SET strategy_template_id = (SELECT id FROM strategy_template WHERE strategy_name = 'Train the trainer')
WHERE id = 21 AND organization_id = 28;

-- Link org 29 strategies to templates
UPDATE learning_strategy SET strategy_template_id = (SELECT id FROM strategy_template WHERE strategy_name = 'SE for managers')
WHERE id = 26 AND organization_id = 29;

UPDATE learning_strategy SET strategy_template_id = (SELECT id FROM strategy_template WHERE strategy_name = 'Train the trainer')
WHERE id = 28 AND organization_id = 29;

UPDATE learning_strategy SET strategy_template_id = (SELECT id FROM strategy_template WHERE strategy_name = 'Needs-based, project-oriented training')
WHERE id = 29 AND organization_id = 29;

UPDATE learning_strategy SET strategy_template_id = (SELECT id FROM strategy_template WHERE strategy_name = 'Common basic understanding')
WHERE id = 30 AND organization_id = 29;

UPDATE learning_strategy SET strategy_template_id = (SELECT id FROM strategy_template WHERE strategy_name = 'Orientation in pilot project')
WHERE id = 31 AND organization_id = 29;

UPDATE learning_strategy SET strategy_template_id = (SELECT id FROM strategy_template WHERE strategy_name = 'Continuous support')
WHERE id = 32 AND organization_id = 29;

UPDATE learning_strategy SET strategy_template_id = (SELECT id FROM strategy_template WHERE strategy_name = 'Certification')
WHERE id = 33 AND organization_id = 29;

-- ===================
-- STEP 6: STANDARDIZE STRATEGY NAMES (OPTIONAL)
-- ===================

-- Update strategy_name to match canonical template names
-- This makes the transition smoother while we still use the old column

UPDATE learning_strategy
SET strategy_name = st.strategy_name
FROM strategy_template st
WHERE learning_strategy.strategy_template_id = st.id
AND learning_strategy.strategy_name != st.strategy_name;

-- ===================
-- STEP 7: ADD CONSTRAINTS
-- ===================

-- After all data is migrated, make strategy_template_id NOT NULL
-- (Commented out - enable after verifying all records migrated)

-- ALTER TABLE learning_strategy ALTER COLUMN strategy_template_id SET NOT NULL;

-- Add unique constraint: one instance per organization per template
-- (Commented out - enable after verifying no duplicates)

-- ALTER TABLE learning_strategy ADD CONSTRAINT unique_org_strategy_template
--     UNIQUE (organization_id, strategy_template_id);

-- ===================
-- VERIFICATION QUERIES
-- ===================

-- Verify template creation
SELECT 'Strategy Templates Created' as check_type, COUNT(*) as count
FROM strategy_template;

-- Verify template competencies
SELECT 'Template Competencies' as check_type,
       st.strategy_name,
       COUNT(stc.id) as competency_count
FROM strategy_template st
LEFT JOIN strategy_template_competency stc ON st.id = stc.strategy_template_id
GROUP BY st.id, st.strategy_name
ORDER BY st.id;

-- Verify learning_strategy migration
SELECT 'Learning Strategy Migration' as check_type,
       COUNT(*) as total_strategies,
       COUNT(strategy_template_id) as linked_to_template,
       COUNT(*) - COUNT(strategy_template_id) as not_linked
FROM learning_strategy;

-- List all organizations and their strategies
SELECT 'Organization Strategies' as check_type,
       ls.organization_id,
       st.strategy_name,
       ls.selected,
       ls.priority
FROM learning_strategy ls
JOIN strategy_template st ON ls.strategy_template_id = st.id
ORDER BY ls.organization_id, ls.priority;

COMMIT;

-- ===================
-- POST-MIGRATION NOTES
-- ===================

-- After verifying migration success:
-- 1. Update backend code to use strategy_template_competency instead of strategy_competency
-- 2. Update pathway services to join through strategy_template
-- 3. After 1 month of stable operation, can optionally:
--    - Make strategy_template_id NOT NULL
--    - Add unique constraint (org_id, template_id)
--    - Deprecate old strategy_competency table (keep for rollback)
--    - Remove strategy_name, strategy_description columns from learning_strategy (optional)

-- ===================
-- END OF MIGRATION
-- ===================
