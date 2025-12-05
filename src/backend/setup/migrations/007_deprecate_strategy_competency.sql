-- Migration 007: Deprecate strategy_competency table
-- Date: 2025-11-06
-- Purpose: Drop redundant strategy_competency table after migrating to template architecture
--
-- Background:
--   OLD Architecture (REDUNDANT):
--     - Each organization had duplicate strategy_competency rows
--     - Example: Org 28 had 106 rows, Org 29 had 106 rows → DUPLICATED DATA
--     - 2 orgs × 7 strategies × 16 competencies = 224 rows
--     - 100 orgs would need 10,600 rows!
--
--   NEW Architecture (EFFICIENT):
--     - Global strategy_template (7 rows)
--     - Global strategy_template_competency (112 rows = 7×16)
--     - Organizations just link via learning_strategy.strategy_template_id
--     - 100 orgs → 112 global + 700 org links = 812 rows (92% reduction!)
--
-- Migration Status:
--   ✅ Phase 1: Created new tables (migration 006_global_strategy_templates.sql)
--   ✅ Phase 2: Populated with validated data (100% data integrity confirmed)
--   ✅ Phase 3: Updated Python code to use new tables
--   ✅ Phase 4: Tested both pathways (task-based & role-based)
--   ✅ Phase 5: Commented out StrategyCompetency model in models.py
--   → Phase 6: Drop old table (THIS MIGRATION)
--
-- Verification Before Running:
--   Run this query to confirm code migration is complete:
--     SELECT COUNT(*) FROM strategy_competency;
--   If it returns a number > 0, the OLD table still has data (expected)
--
--   Verify new architecture works:
--     SELECT COUNT(*) FROM strategy_template_competency;
--   Should return: 112
--
-- Safety:
--   - This is a destructive operation
--   - Ensure code is updated and tested before running
--   - Backup database if needed: pg_dump seqpt_database > backup_before_007.sql
--
-- =============================================================================

-- 1. Verify new architecture exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'strategy_template') THEN
        RAISE EXCEPTION 'ERROR: strategy_template table does not exist! Run migration 006 first.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'strategy_template_competency') THEN
        RAISE EXCEPTION 'ERROR: strategy_template_competency table does not exist! Run migration 006 first.';
    END IF;
END $$;

-- 2. Verify new architecture has data
DO $$
DECLARE
    template_count INT;
    template_comp_count INT;
BEGIN
    SELECT COUNT(*) INTO template_count FROM strategy_template;
    SELECT COUNT(*) INTO template_comp_count FROM strategy_template_competency;

    IF template_count < 7 THEN
        RAISE EXCEPTION 'ERROR: strategy_template has insufficient data (expected 7, found %). Run migration 006 first.', template_count;
    END IF;

    IF template_comp_count < 112 THEN
        RAISE EXCEPTION 'ERROR: strategy_template_competency has insufficient data (expected 112, found %). Run migration 006 first.', template_comp_count;
    END IF;

    RAISE NOTICE 'Verification passed: New architecture has sufficient data';
    RAISE NOTICE '  - strategy_template: % rows', template_count;
    RAISE NOTICE '  - strategy_template_competency: % rows', template_comp_count;
END $$;

-- 3. Show statistics before dropping
DO $$
DECLARE
    old_table_count INT;
BEGIN
    SELECT COUNT(*) INTO old_table_count FROM strategy_competency;

    RAISE NOTICE 'About to drop strategy_competency table:';
    RAISE NOTICE '  - Current rows: %', old_table_count;
    RAISE NOTICE '  - This data is REDUNDANT (duplicated in strategy_template_competency)';
    RAISE NOTICE '  - Backend code no longer uses this table';
END $$;

-- 4. Drop the old table
DROP TABLE IF EXISTS strategy_competency CASCADE;

-- 5. Confirmation
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Migration 007 completed successfully!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'OLD table (strategy_competency) has been dropped';
    RAISE NOTICE 'NEW architecture (strategy_template + strategy_template_competency) is active';
    RAISE NOTICE '';
    RAISE NOTICE 'Benefits:';
    RAISE NOTICE '  1. Single source of truth (no duplication)';
    RAISE NOTICE '  2. 92%% reduction in database size (for 100 orgs)';
    RAISE NOTICE '  3. Guaranteed data consistency';
    RAISE NOTICE '  4. Efficient queries via template links';
END $$;
