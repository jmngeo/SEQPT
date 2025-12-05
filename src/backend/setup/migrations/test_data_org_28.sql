-- Test Data for Organization 28 - Phase 2 Algorithm Testing
-- Created: 2025-11-04
-- Purpose: Populate test data for role-based pathway algorithm integration testing

-- ============================================================================
-- 1. Create Organization Roles (if not exists)
-- ============================================================================

-- Insert standard SE roles for organization 28
INSERT INTO organization_roles (organization_id, role_name, role_description, standard_role_cluster_id, identification_method, participating_in_training)
VALUES
    (28, 'Systems Engineer', 'Core systems engineering role responsible for architecture and integration', 1, 'STANDARD', true),
    (28, 'Requirements Engineer', 'Specialist in requirements elicitation and management', 3, 'STANDARD', true),
    (28, 'Project Manager', 'Project leadership and coordination', 7, 'STANDARD', true)
ON CONFLICT (organization_id, role_name) DO NOTHING;

-- ============================================================================
-- 2. Create Role-Competency Matrix Entries
-- ============================================================================

-- Get the role IDs for organization 28
DO $$
DECLARE
    se_role_id INTEGER;
    req_role_id INTEGER;
    pm_role_id INTEGER;
BEGIN
    -- Get role IDs
    SELECT id INTO se_role_id FROM organization_roles WHERE organization_id = 28 AND role_name = 'Systems Engineer';
    SELECT id INTO req_role_id FROM organization_roles WHERE organization_id = 28 AND role_name = 'Requirements Engineer';
    SELECT id INTO pm_role_id FROM organization_roles WHERE organization_id = 28 AND role_name = 'Project Manager';

    -- Systems Engineer competency requirements (high technical competencies)
    INSERT INTO role_competency_matrix (organization_id, role_cluster_id, competency_id, role_competency_value)
    SELECT 28, se_role_id, comp_id, req_level
    FROM (VALUES
        (1, 4),  -- Systems Thinking: 4 (independent)
        (2, 4),  -- Holistic Thinking: 4
        (3, 6),  -- Systems Engineering: 6 (expert)
        (4, 4),  -- Analytical Thinking: 4
        (5, 4),  -- Interdisciplinary Skills: 4
        (6, 4),  -- Communication: 4
        (7, 4),  -- Requirements Engineering: 4
        (8, 4),  -- System Architecture: 4
        (9, 4),  -- Modeling/Simulation: 4
        (10, 2), -- Verification/Validation: 2
        (11, 2), -- Project Management: 2
        (12, 2), -- Configuration Management: 2
        (13, 2), -- Risk Management: 2
        (14, 2), -- Quality Assurance: 2
        (15, 1), -- Procurement: 1
        (16, 1)  -- Lifecycle Management: 1
    ) AS reqs(comp_id, req_level)
    ON CONFLICT (organization_id, role_cluster_id, competency_id) DO UPDATE
    SET role_competency_value = EXCLUDED.role_competency_value;

    -- Requirements Engineer competency requirements (high requirements focus)
    INSERT INTO role_competency_matrix (organization_id, role_cluster_id, competency_id, role_competency_value)
    SELECT 28, req_role_id, comp_id, req_level
    FROM (VALUES
        (1, 4),  -- Systems Thinking: 4
        (2, 4),  -- Holistic Thinking: 4
        (3, 2),  -- Systems Engineering: 2
        (4, 6),  -- Analytical Thinking: 6 (expert)
        (5, 4),  -- Interdisciplinary Skills: 4
        (6, 4),  -- Communication: 4
        (7, 6),  -- Requirements Engineering: 6 (expert)
        (8, 2),  -- System Architecture: 2
        (9, 2),  -- Modeling/Simulation: 2
        (10, 2), -- Verification/Validation: 2
        (11, 1), -- Project Management: 1
        (12, 2), -- Configuration Management: 2
        (13, 2), -- Risk Management: 2
        (14, 2), -- Quality Assurance: 2
        (15, 1), -- Procurement: 1
        (16, 1)  -- Lifecycle Management: 1
    ) AS reqs(comp_id, req_level)
    ON CONFLICT (organization_id, role_cluster_id, competency_id) DO UPDATE
    SET role_competency_value = EXCLUDED.role_competency_value;

    -- Project Manager competency requirements (high management focus)
    INSERT INTO role_competency_matrix (organization_id, role_cluster_id, competency_id, role_competency_value)
    SELECT 28, pm_role_id, comp_id, req_level
    FROM (VALUES
        (1, 4),  -- Systems Thinking: 4
        (2, 4),  -- Holistic Thinking: 4
        (3, 2),  -- Systems Engineering: 2
        (4, 4),  -- Analytical Thinking: 4
        (5, 4),  -- Interdisciplinary Skills: 4
        (6, 6),  -- Communication: 6 (expert)
        (7, 2),  -- Requirements Engineering: 2
        (8, 2),  -- System Architecture: 2
        (9, 1),  -- Modeling/Simulation: 1
        (10, 2), -- Verification/Validation: 2
        (11, 6), -- Project Management: 6 (expert)
        (12, 4), -- Configuration Management: 4
        (13, 6), -- Risk Management: 6 (expert)
        (14, 4), -- Quality Assurance: 4
        (15, 4), -- Procurement: 4
        (16, 4)  -- Lifecycle Management: 4
    ) AS reqs(comp_id, req_level)
    ON CONFLICT (organization_id, role_cluster_id, competency_id) DO UPDATE
    SET role_competency_value = EXCLUDED.role_competency_value;

    RAISE NOTICE '[OK] Role-competency matrix populated for organization 28';
END $$;

-- ============================================================================
-- 3. Create Learning Strategies
-- ============================================================================

INSERT INTO learning_strategy (organization_id, strategy_name, strategy_description, selected, priority)
VALUES
    (28, 'Foundation Workshop', 'Introductory workshop covering SE fundamentals and basic competencies', true, 1),
    (28, 'Advanced Training Program', 'Comprehensive training for advanced SE competencies', true, 2),
    (28, 'Expert Certification', 'Expert-level certification program for senior engineers', false, 3)
ON CONFLICT (organization_id, strategy_name) DO UPDATE
SET selected = EXCLUDED.selected, priority = EXCLUDED.priority;

-- ============================================================================
-- 4. Create Strategy-Competency Mappings
-- ============================================================================

DO $$
DECLARE
    foundation_id INTEGER;
    advanced_id INTEGER;
    expert_id INTEGER;
BEGIN
    -- Get strategy IDs
    SELECT id INTO foundation_id FROM learning_strategy WHERE organization_id = 28 AND strategy_name = 'Foundation Workshop';
    SELECT id INTO advanced_id FROM learning_strategy WHERE organization_id = 28 AND strategy_name = 'Advanced Training Program';
    SELECT id INTO expert_id FROM learning_strategy WHERE organization_id = 28 AND strategy_name = 'Expert Certification';

    -- Foundation Workshop: targets basic levels (1-2) for most competencies
    INSERT INTO strategy_competency (strategy_id, competency_id, target_level)
    SELECT foundation_id, comp_id, target
    FROM (VALUES
        (1, 2),   -- Systems Thinking: 2
        (2, 2),   -- Holistic Thinking: 2
        (3, 2),   -- Systems Engineering: 2
        (4, 2),   -- Analytical Thinking: 2
        (5, 2),   -- Interdisciplinary Skills: 2
        (6, 2),   -- Communication: 2
        (7, 2),   -- Requirements Engineering: 2
        (8, 1),   -- System Architecture: 1
        (9, 1),   -- Modeling/Simulation: 1
        (10, 1),  -- Verification/Validation: 1
        (11, 2),  -- Project Management: 2
        (12, 1),  -- Configuration Management: 1
        (13, 2),  -- Risk Management: 2
        (14, 1),  -- Quality Assurance: 1
        (15, 1),  -- Procurement: 1
        (16, 1)   -- Lifecycle Management: 1
    ) AS targets(comp_id, target)
    ON CONFLICT (strategy_id, competency_id) DO UPDATE
    SET target_level = EXCLUDED.target_level;

    -- Advanced Training: targets intermediate-advanced levels (2-4)
    INSERT INTO strategy_competency (strategy_id, competency_id, target_level)
    SELECT advanced_id, comp_id, target
    FROM (VALUES
        (1, 4),   -- Systems Thinking: 4
        (2, 4),   -- Holistic Thinking: 4
        (3, 4),   -- Systems Engineering: 4
        (4, 4),   -- Analytical Thinking: 4
        (5, 4),   -- Interdisciplinary Skills: 4
        (6, 4),   -- Communication: 4
        (7, 4),   -- Requirements Engineering: 4
        (8, 4),   -- System Architecture: 4
        (9, 2),   -- Modeling/Simulation: 2
        (10, 2),  -- Verification/Validation: 2
        (11, 4),  -- Project Management: 4
        (12, 2),  -- Configuration Management: 2
        (13, 4),  -- Risk Management: 4
        (14, 2),  -- Quality Assurance: 2
        (15, 2),  -- Procurement: 2
        (16, 2)   -- Lifecycle Management: 2
    ) AS targets(comp_id, target)
    ON CONFLICT (strategy_id, competency_id) DO UPDATE
    SET target_level = EXCLUDED.target_level;

    -- Expert Certification: targets expert levels (6) for key competencies
    INSERT INTO strategy_competency (strategy_id, competency_id, target_level)
    SELECT expert_id, comp_id, target
    FROM (VALUES
        (1, 6),   -- Systems Thinking: 6
        (2, 6),   -- Holistic Thinking: 6
        (3, 6),   -- Systems Engineering: 6
        (4, 6),   -- Analytical Thinking: 6
        (5, 6),   -- Interdisciplinary Skills: 6
        (6, 6),   -- Communication: 6
        (7, 6),   -- Requirements Engineering: 6
        (8, 6),   -- System Architecture: 6
        (9, 4),   -- Modeling/Simulation: 4
        (10, 4),  -- Verification/Validation: 4
        (11, 6),  -- Project Management: 6
        (12, 4),  -- Configuration Management: 4
        (13, 6),  -- Risk Management: 6
        (14, 4),  -- Quality Assurance: 4
        (15, 4),  -- Procurement: 4
        (16, 4)   -- Lifecycle Management: 4
    ) AS targets(comp_id, target)
    ON CONFLICT (strategy_id, competency_id) DO UPDATE
    SET target_level = EXCLUDED.target_level;

    RAISE NOTICE '[OK] Strategy-competency mappings created for organization 28';
END $$;

-- ============================================================================
-- 5. Update User Assessments with Role Selection
-- ============================================================================

-- Update existing assessments to include role selections
DO $$
DECLARE
    se_role_id INTEGER;
    assessment_record RECORD;
BEGIN
    -- Get Systems Engineer role ID
    SELECT id INTO se_role_id FROM organization_roles WHERE organization_id = 28 AND role_name = 'Systems Engineer';

    -- Update assessments to include role selection
    FOR assessment_record IN
        SELECT id FROM user_assessment WHERE organization_id = 28 AND completed_at IS NOT NULL
    LOOP
        UPDATE user_assessment
        SET selected_roles = jsonb_build_array(se_role_id)
        WHERE id = assessment_record.id AND (selected_roles IS NULL OR selected_roles = '[]'::jsonb);
    END LOOP;

    RAISE NOTICE '[OK] User assessments updated with role selections';
END $$;

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Summary of test data created
DO $$
DECLARE
    role_count INTEGER;
    strategy_count INTEGER;
    rcm_count INTEGER;
    sc_count INTEGER;
    assessment_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO role_count FROM organization_roles WHERE organization_id = 28;
    SELECT COUNT(*) INTO strategy_count FROM learning_strategy WHERE organization_id = 28;
    SELECT COUNT(*) INTO rcm_count FROM role_competency_matrix WHERE organization_id = 28;
    SELECT COUNT(*) INTO sc_count
    FROM strategy_competency sc
    JOIN learning_strategy ls ON sc.strategy_id = ls.id
    WHERE ls.organization_id = 28;
    SELECT COUNT(*) INTO assessment_count
    FROM user_assessment
    WHERE organization_id = 28 AND completed_at IS NOT NULL AND selected_roles IS NOT NULL;

    RAISE NOTICE '================================================================';
    RAISE NOTICE 'TEST DATA SUMMARY FOR ORGANIZATION 28:';
    RAISE NOTICE '================================================================';
    RAISE NOTICE 'Roles created: %', role_count;
    RAISE NOTICE 'Learning strategies created: %', strategy_count;
    RAISE NOTICE 'Role-competency mappings: %', rcm_count;
    RAISE NOTICE 'Strategy-competency mappings: %', sc_count;
    RAISE NOTICE 'Completed assessments with roles: %', assessment_count;
    RAISE NOTICE '================================================================';

    IF role_count >= 3 AND strategy_count >= 2 AND rcm_count >= 40 AND sc_count >= 40 AND assessment_count > 0 THEN
        RAISE NOTICE '[SUCCESS] Test data created successfully for organization 28';
    ELSE
        RAISE WARNING '[WARNING] Test data may be incomplete';
    END IF;
END $$;
