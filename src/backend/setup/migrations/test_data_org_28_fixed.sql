-- Test Data for Organization 28 - Phase 2 Algorithm Testing (FIXED)
-- Created: 2025-11-04
-- Purpose: Populate test data for role-based pathway algorithm integration testing

-- ============================================================================
-- 0. Clean up existing test data (optional - comment out if you want to keep)
-- ============================================================================
DELETE FROM strategy_competency WHERE strategy_id IN (SELECT id FROM learning_strategy WHERE organization_id = 28);
DELETE FROM learning_strategy WHERE organization_id = 28;
DELETE FROM role_competency_matrix WHERE organization_id = 28;
DELETE FROM organization_roles WHERE organization_id = 28;

-- ============================================================================
-- 1. Create Organization Roles
-- ============================================================================

INSERT INTO organization_roles (organization_id, role_name, role_description, standard_role_cluster_id, identification_method, participating_in_training)
VALUES
    (28, 'Systems Engineer', 'Core systems engineering role', 1, 'STANDARD', true),
    (28, 'Requirements Engineer', 'Requirements specialist', 3, 'STANDARD', true),
    (28, 'Project Manager', 'Project leadership', 7, 'STANDARD', true);

-- ============================================================================
-- 2. Create Role-Competency Matrix (using actual competency IDs: 1, 4-18)
-- ============================================================================

-- Get role IDs and populate competency matrix
DO $$
DECLARE
    se_role_id INTEGER;
    req_role_id INTEGER;
    pm_role_id INTEGER;
BEGIN
    SELECT id INTO se_role_id FROM organization_roles WHERE organization_id = 28 AND role_name = 'Systems Engineer';
    SELECT id INTO req_role_id FROM organization_roles WHERE organization_id = 28 AND role_name = 'Requirements Engineer';
    SELECT id INTO pm_role_id FROM organization_roles WHERE organization_id = 28 AND role_name = 'Project Manager';

    -- Systems Engineer: High technical competencies
    INSERT INTO role_competency_matrix (organization_id, role_cluster_id, competency_id, role_competency_value) VALUES
        (28, se_role_id, 1, 4),   -- Systems Thinking: 4
        (28, se_role_id, 4, 4),   -- Lifecycle Consideration: 4
        (28, se_role_id, 5, 4),   -- Customer Orientation: 4
        (28, se_role_id, 6, 6),   -- Systems Modeling: 6 (expert)
        (28, se_role_id, 7, 4),   -- Communication: 4
        (28, se_role_id, 8, 2),   -- Leadership: 2
        (28, se_role_id, 9, 4),   -- Self-Organization: 4
        (28, se_role_id, 10, 2),  -- Project Management: 2
        (28, se_role_id, 11, 4),  -- Decision Management: 4
        (28, se_role_id, 12, 4),  -- Information Management: 4
        (28, se_role_id, 13, 2),  -- Configuration Management: 2
        (28, se_role_id, 14, 4),  -- Requirements Definition: 4
        (28, se_role_id, 15, 6),  -- System Architecting: 6 (expert)
        (28, se_role_id, 16, 4),  -- Integration/Verification: 4
        (28, se_role_id, 17, 2),  -- Operation Support: 2
        (28, se_role_id, 18, 2);  -- Agile Methods: 2

    -- Requirements Engineer: High requirements focus
    INSERT INTO role_competency_matrix (organization_id, role_cluster_id, competency_id, role_competency_value) VALUES
        (28, req_role_id, 1, 4),   -- Systems Thinking: 4
        (28, req_role_id, 4, 4),   -- Lifecycle Consideration: 4
        (28, req_role_id, 5, 6),   -- Customer Orientation: 6 (expert)
        (28, req_role_id, 6, 4),   -- Systems Modeling: 4
        (28, req_role_id, 7, 4),   -- Communication: 4
        (28, req_role_id, 8, 2),   -- Leadership: 2
        (28, req_role_id, 9, 4),   -- Self-Organization: 4
        (28, req_role_id, 10, 1),  -- Project Management: 1
        (28, req_role_id, 11, 4),  -- Decision Management: 4
        (28, req_role_id, 12, 4),  -- Information Management: 4
        (28, req_role_id, 13, 2),  -- Configuration Management: 2
        (28, req_role_id, 14, 6),  -- Requirements Definition: 6 (expert)
        (28, req_role_id, 15, 2),  -- System Architecting: 2
        (28, req_role_id, 16, 2),  -- Integration/Verification: 2
        (28, req_role_id, 17, 1),  -- Operation Support: 1
        (28, req_role_id, 18, 2);  -- Agile Methods: 2

    -- Project Manager: High management focus
    INSERT INTO role_competency_matrix (organization_id, role_cluster_id, competency_id, role_competency_value) VALUES
        (28, pm_role_id, 1, 4),   -- Systems Thinking: 4
        (28, pm_role_id, 4, 4),   -- Lifecycle Consideration: 4
        (28, pm_role_id, 5, 4),   -- Customer Orientation: 4
        (28, pm_role_id, 6, 2),   -- Systems Modeling: 2
        (28, pm_role_id, 7, 6),   -- Communication: 6 (expert)
        (28, pm_role_id, 8, 6),   -- Leadership: 6 (expert)
        (28, pm_role_id, 9, 4),   -- Self-Organization: 4
        (28, pm_role_id, 10, 6),  -- Project Management: 6 (expert)
        (28, pm_role_id, 11, 6),  -- Decision Management: 6 (expert)
        (28, pm_role_id, 12, 4),  -- Information Management: 4
        (28, pm_role_id, 13, 4),  -- Configuration Management: 4
        (28, pm_role_id, 14, 2),  -- Requirements Definition: 2
        (28, pm_role_id, 15, 2),  -- System Architecting: 2
        (28, pm_role_id, 16, 2),  -- Integration/Verification: 2
        (28, pm_role_id, 17, 2),  -- Operation Support: 2
        (28, pm_role_id, 18, 4);  -- Agile Methods: 4

    RAISE NOTICE '[OK] Created % role-competency mappings', 48;
END $$;

-- ============================================================================
-- 3. Create Learning Strategies
-- ============================================================================

INSERT INTO learning_strategy (organization_id, strategy_name, strategy_description, selected, priority)
VALUES
    (28, 'Foundation Workshop', 'Introductory SE fundamentals workshop', true, 1),
    (28, 'Advanced Training', 'Advanced SE competency training', true, 2);

-- ============================================================================
-- 4. Create Strategy-Competency Mappings
-- ============================================================================

DO $$
DECLARE
    foundation_id INTEGER;
    advanced_id INTEGER;
BEGIN
    SELECT id INTO foundation_id FROM learning_strategy WHERE organization_id = 28 AND strategy_name = 'Foundation Workshop';
    SELECT id INTO advanced_id FROM learning_strategy WHERE organization_id = 28 AND strategy_name = 'Advanced Training';

    -- Foundation Workshop: targets basic levels (1-2)
    INSERT INTO strategy_competency (strategy_id, competency_id, target_level) VALUES
        (foundation_id, 1, 2),   -- Systems Thinking
        (foundation_id, 4, 2),   -- Lifecycle Consideration
        (foundation_id, 5, 2),   -- Customer Orientation
        (foundation_id, 6, 2),   -- Systems Modeling
        (foundation_id, 7, 2),   -- Communication
        (foundation_id, 8, 1),   -- Leadership
        (foundation_id, 9, 2),   -- Self-Organization
        (foundation_id, 10, 2),  -- Project Management
        (foundation_id, 11, 2),  -- Decision Management
        (foundation_id, 12, 2),  -- Information Management
        (foundation_id, 13, 1),  -- Configuration Management
        (foundation_id, 14, 2),  -- Requirements Definition
        (foundation_id, 15, 1),  -- System Architecting
        (foundation_id, 16, 1),  -- Integration/Verification
        (foundation_id, 17, 1),  -- Operation Support
        (foundation_id, 18, 1);  -- Agile Methods

    -- Advanced Training: targets intermediate-advanced levels (2-4)
    INSERT INTO strategy_competency (strategy_id, competency_id, target_level) VALUES
        (advanced_id, 1, 4),   -- Systems Thinking
        (advanced_id, 4, 4),   -- Lifecycle Consideration
        (advanced_id, 5, 4),   -- Customer Orientation
        (advanced_id, 6, 4),   -- Systems Modeling
        (advanced_id, 7, 4),   -- Communication
        (advanced_id, 8, 4),   -- Leadership
        (advanced_id, 9, 4),   -- Self-Organization
        (advanced_id, 10, 4),  -- Project Management
        (advanced_id, 11, 4),  -- Decision Management
        (advanced_id, 12, 4),  -- Information Management
        (advanced_id, 13, 2),  -- Configuration Management
        (advanced_id, 14, 4),  -- Requirements Definition
        (advanced_id, 15, 4),  -- System Architecting
        (advanced_id, 16, 2),  -- Integration/Verification
        (advanced_id, 17, 2),  -- Operation Support
        (advanced_id, 18, 2);  -- Agile Methods

    RAISE NOTICE '[OK] Created % strategy-competency mappings', 32;
END $$;

-- ============================================================================
-- 5. Update User Assessments with Role Selection
-- ============================================================================

DO $$
DECLARE
    se_role_id INTEGER;
    updated_count INTEGER := 0;
BEGIN
    SELECT id INTO se_role_id FROM organization_roles WHERE organization_id = 28 AND role_name = 'Systems Engineer';

    UPDATE user_assessment
    SET selected_roles = jsonb_build_array(se_role_id)
    WHERE organization_id = 28
      AND completed_at IS NOT NULL
      AND (selected_roles IS NULL OR selected_roles = '[]'::jsonb);

    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE '[OK] Updated % assessments with role selection', updated_count;
END $$;

-- ============================================================================
-- Final Summary
-- ============================================================================

DO $$
DECLARE
    role_count INTEGER;
    strategy_count INTEGER;
    rcm_count INTEGER;
    sc_count INTEGER;
    assessment_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO role_count FROM organization_roles WHERE organization_id = 28;
    SELECT COUNT(*) INTO strategy_count FROM learning_strategy WHERE organization_id = 28 AND selected = true;
    SELECT COUNT(*) INTO rcm_count FROM role_competency_matrix WHERE organization_id = 28;
    SELECT COUNT(*) INTO sc_count
    FROM strategy_competency sc
    JOIN learning_strategy ls ON sc.strategy_id = ls.id
    WHERE ls.organization_id = 28;
    SELECT COUNT(*) INTO assessment_count
    FROM user_assessment
    WHERE organization_id = 28 AND completed_at IS NOT NULL AND selected_roles IS NOT NULL;

    RAISE NOTICE '================================================================';
    RAISE NOTICE 'TEST DATA SUMMARY - ORGANIZATION 28';
    RAISE NOTICE '================================================================';
    RAISE NOTICE 'Roles: %', role_count;
    RAISE NOTICE 'Selected strategies: %', strategy_count;
    RAISE NOTICE 'Role-competency mappings: %', rcm_count;
    RAISE NOTICE 'Strategy-competency mappings: %', sc_count;
    RAISE NOTICE 'Assessments with roles: %', assessment_count;
    RAISE NOTICE '================================================================';

    IF role_count >= 3 AND strategy_count >= 2 AND rcm_count >= 40 AND sc_count >= 30 AND assessment_count > 0 THEN
        RAISE NOTICE '[SUCCESS] Test data ready for integration testing!';
    ELSE
        RAISE WARNING '[WARNING] Test data incomplete';
    END IF;
END $$;
