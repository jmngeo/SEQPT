-- Migration 012: Fix strategy_template_id for all learning_strategy records
--
-- Issue: When strategies are saved in Phase 1 Task 3, the strategy_template_id
-- was not being set. This caused LO generation to fail because it couldn't find
-- the target competencies from strategy_template_competency table.
--
-- Solution: Map strategy names to their corresponding strategy_template IDs
-- based on case-insensitive partial matching.
--
-- Run with: psql -h localhost -U seqpt_admin -d seqpt_database -f this_file.sql

-- First, show current state
SELECT 'Before fix:' as status;
SELECT id, organization_id, strategy_name, strategy_template_id
FROM learning_strategy
WHERE strategy_template_id IS NULL
ORDER BY organization_id, id;

-- Update based on strategy name patterns
-- 1 = Common basic understanding
UPDATE learning_strategy SET strategy_template_id = 1
WHERE strategy_template_id IS NULL
AND (LOWER(strategy_name) LIKE '%common%understanding%'
     OR LOWER(strategy_name) LIKE '%common%basic%');

-- 2 = SE for managers
UPDATE learning_strategy SET strategy_template_id = 2
WHERE strategy_template_id IS NULL
AND LOWER(strategy_name) LIKE '%manager%';

-- 3 = Orientation in pilot project / Foundation Workshop
UPDATE learning_strategy SET strategy_template_id = 3
WHERE strategy_template_id IS NULL
AND (LOWER(strategy_name) LIKE '%pilot%project%'
     OR LOWER(strategy_name) LIKE '%foundation%workshop%'
     OR LOWER(strategy_name) LIKE '%orientation%');

-- 4 = Needs-based, project-oriented training / Advanced Training
UPDATE learning_strategy SET strategy_template_id = 4
WHERE strategy_template_id IS NULL
AND (LOWER(strategy_name) LIKE '%needs%based%'
     OR LOWER(strategy_name) LIKE '%project%oriented%training%'
     OR LOWER(strategy_name) LIKE '%advanced%training%');

-- 5 = Continuous support
UPDATE learning_strategy SET strategy_template_id = 5
WHERE strategy_template_id IS NULL
AND LOWER(strategy_name) LIKE '%continuous%support%';

-- 6 = Train the trainer / Train the SE-Trainer
UPDATE learning_strategy SET strategy_template_id = 6
WHERE strategy_template_id IS NULL
AND (LOWER(strategy_name) LIKE '%train%trainer%'
     OR LOWER(strategy_name) LIKE '%train%se%trainer%');

-- 7 = Certification
UPDATE learning_strategy SET strategy_template_id = 7
WHERE strategy_template_id IS NULL
AND LOWER(strategy_name) LIKE '%certification%';

-- Show remaining unmatched (if any)
SELECT 'After fix - remaining unmatched:' as status;
SELECT id, organization_id, strategy_name, strategy_template_id
FROM learning_strategy
WHERE strategy_template_id IS NULL
ORDER BY organization_id, id;

-- Show summary
SELECT 'Summary by template:' as status;
SELECT
    st.strategy_name as template_name,
    COUNT(ls.id) as strategy_count
FROM strategy_template st
LEFT JOIN learning_strategy ls ON ls.strategy_template_id = st.id
GROUP BY st.id, st.strategy_name
ORDER BY st.id;

-- Also clear any cached LO results since input hash changed
DELETE FROM generated_learning_objectives
WHERE organization_id IN (
    SELECT DISTINCT organization_id FROM learning_strategy
);

SELECT 'LO cache cleared for all organizations' as status;
