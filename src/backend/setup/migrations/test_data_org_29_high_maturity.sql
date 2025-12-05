-- ============================================================================
-- Test Data for Organization 29 - HIGH MATURITY (Role-Based Pathway)
-- ============================================================================
-- Created: 2025-11-06
-- Purpose: Comprehensive test data for role-based pathway with high maturity
--
-- Characteristics:
-- - Maturity Level: 4 (Quantitatively Managed) - triggers role-based pathway
-- - 4 distinct roles with varied competency requirements
-- - 20 users with diverse competency levels
-- - 3 learning strategies (2 selected)
-- - Realistic scenario distribution (A, B, C, D)
-- - Mix of competency gaps and achievements
-- ============================================================================

-- ============================================================================
-- 0. Clean up existing test data for org 29
-- ============================================================================
DELETE FROM user_se_competency_survey_results WHERE assessment_id IN (
    SELECT id FROM user_assessment WHERE organization_id = 29
);
DELETE FROM user_assessment WHERE organization_id = 29;
DELETE FROM new_survey_user WHERE organization_id = 29 AND username LIKE 'org29_%';
DELETE FROM strategy_competency WHERE strategy_id IN (
    SELECT id FROM learning_strategy WHERE organization_id = 29
);
DELETE FROM learning_strategy WHERE organization_id = 29;
DELETE FROM role_competency_matrix WHERE organization_id = 29;
DELETE FROM organization_roles WHERE organization_id = 29;
DELETE FROM phase_questionnaire_responses WHERE organization_id = 29;

-- ============================================================================
-- 1. Create Phase 1 Maturity Assessment (Level 4 - High Maturity)
-- ============================================================================
INSERT INTO phase_questionnaire_responses (
    organization_id,
    questionnaire_type,
    phase,
    responses,
    completed_at,
    created_at
) VALUES (
    29,
    'maturity',
    1,
    jsonb_build_object(
        'results', jsonb_build_object(
            'strategyInputs', jsonb_build_object(
                'seProcessesValue', 4,
                'seProcessesDescription', 'Quantitatively Managed',
                'maturityScore', 76.5
            )
        )
    ),
    NOW() - interval '30 days',
    NOW() - interval '30 days'
);

-- ============================================================================
-- 2. Create Organization Roles (4 distinct roles)
-- ============================================================================
INSERT INTO organization_roles (
    organization_id,
    role_name,
    role_description,
    standard_role_cluster_id,
    identification_method,
    participating_in_training
) VALUES
    (29, 'Lead Systems Engineer', 'Senior systems engineering role', 1, 'STANDARD', true),
    (29, 'Requirements Analyst', 'Requirements engineering specialist', 3, 'STANDARD', true),
    (29, 'Architecture Lead', 'System architecture design lead', 2, 'STANDARD', true),
    (29, 'Integration Engineer', 'System integration and verification', 5, 'STANDARD', true);

-- ============================================================================
-- 3. Create Role-Competency Matrix
-- ============================================================================
DO $$
DECLARE
    lead_se_role_id INTEGER;
    req_analyst_role_id INTEGER;
    arch_lead_role_id INTEGER;
    integ_eng_role_id INTEGER;
BEGIN
    -- Get role IDs
    SELECT id INTO lead_se_role_id FROM organization_roles WHERE organization_id = 29 AND role_name = 'Lead Systems Engineer';
    SELECT id INTO req_analyst_role_id FROM organization_roles WHERE organization_id = 29 AND role_name = 'Requirements Analyst';
    SELECT id INTO arch_lead_role_id FROM organization_roles WHERE organization_id = 29 AND role_name = 'Architecture Lead';
    SELECT id INTO integ_eng_role_id FROM organization_roles WHERE organization_id = 29 AND role_name = 'Integration Engineer';

    -- Lead Systems Engineer: High across the board, expert in modeling
    INSERT INTO role_competency_matrix (organization_id, role_cluster_id, competency_id, role_competency_value) VALUES
        (29, lead_se_role_id, 1, 4),   -- Systems Thinking
        (29, lead_se_role_id, 4, 4),   -- Lifecycle Consideration
        (29, lead_se_role_id, 5, 4),   -- Customer Orientation
        (29, lead_se_role_id, 6, 6),   -- Systems Modeling (expert)
        (29, lead_se_role_id, 7, 4),   -- Communication
        (29, lead_se_role_id, 8, 4),   -- Leadership
        (29, lead_se_role_id, 9, 4),   -- Self-Organization
        (29, lead_se_role_id, 10, 4),  -- Project Management
        (29, lead_se_role_id, 11, 6),  -- Decision Management (expert)
        (29, lead_se_role_id, 12, 4),  -- Information Management
        (29, lead_se_role_id, 13, 4),  -- Configuration Management
        (29, lead_se_role_id, 14, 4),  -- Requirements Definition
        (29, lead_se_role_id, 15, 6),  -- System Architecting (expert)
        (29, lead_se_role_id, 16, 4),  -- Integration/Verification
        (29, lead_se_role_id, 17, 2),  -- Operation Support
        (29, lead_se_role_id, 18, 4);  -- Agile Methods

    -- Requirements Analyst: Expert in requirements, customer focus
    INSERT INTO role_competency_matrix (organization_id, role_cluster_id, competency_id, role_competency_value) VALUES
        (29, req_analyst_role_id, 1, 4),   -- Systems Thinking
        (29, req_analyst_role_id, 4, 4),   -- Lifecycle Consideration
        (29, req_analyst_role_id, 5, 6),   -- Customer Orientation (expert)
        (29, req_analyst_role_id, 6, 4),   -- Systems Modeling
        (29, req_analyst_role_id, 7, 4),   -- Communication
        (29, req_analyst_role_id, 8, 2),   -- Leadership
        (29, req_analyst_role_id, 9, 4),   -- Self-Organization
        (29, req_analyst_role_id, 10, 2),  -- Project Management
        (29, req_analyst_role_id, 11, 4),  -- Decision Management
        (29, req_analyst_role_id, 12, 4),  -- Information Management
        (29, req_analyst_role_id, 13, 2),  -- Configuration Management
        (29, req_analyst_role_id, 14, 6),  -- Requirements Definition (expert)
        (29, req_analyst_role_id, 15, 2),  -- System Architecting
        (29, req_analyst_role_id, 16, 2),  -- Integration/Verification
        (29, req_analyst_role_id, 17, 1),  -- Operation Support
        (29, req_analyst_role_id, 18, 2);  -- Agile Methods

    -- Architecture Lead: Expert in architecting and modeling
    INSERT INTO role_competency_matrix (organization_id, role_cluster_id, competency_id, role_competency_value) VALUES
        (29, arch_lead_role_id, 1, 4),   -- Systems Thinking
        (29, arch_lead_role_id, 4, 4),   -- Lifecycle Consideration
        (29, arch_lead_role_id, 5, 4),   -- Customer Orientation
        (29, arch_lead_role_id, 6, 6),   -- Systems Modeling (expert)
        (29, arch_lead_role_id, 7, 4),   -- Communication
        (29, arch_lead_role_id, 8, 2),   -- Leadership
        (29, arch_lead_role_id, 9, 4),   -- Self-Organization
        (29, arch_lead_role_id, 10, 2),  -- Project Management
        (29, arch_lead_role_id, 11, 4),  -- Decision Management
        (29, arch_lead_role_id, 12, 4),  -- Information Management
        (29, arch_lead_role_id, 13, 4),  -- Configuration Management
        (29, arch_lead_role_id, 14, 4),  -- Requirements Definition
        (29, arch_lead_role_id, 15, 6),  -- System Architecting (expert)
        (29, arch_lead_role_id, 16, 2),  -- Integration/Verification
        (29, arch_lead_role_id, 17, 1),  -- Operation Support
        (29, arch_lead_role_id, 18, 2);  -- Agile Methods

    -- Integration Engineer: Expert in integration/verification
    INSERT INTO role_competency_matrix (organization_id, role_cluster_id, competency_id, role_competency_value) VALUES
        (29, integ_eng_role_id, 1, 4),   -- Systems Thinking
        (29, integ_eng_role_id, 4, 4),   -- Lifecycle Consideration
        (29, integ_eng_role_id, 5, 2),   -- Customer Orientation
        (29, integ_eng_role_id, 6, 4),   -- Systems Modeling
        (29, integ_eng_role_id, 7, 4),   -- Communication
        (29, integ_eng_role_id, 8, 2),   -- Leadership
        (29, integ_eng_role_id, 9, 4),   -- Self-Organization
        (29, integ_eng_role_id, 10, 2),  -- Project Management
        (29, integ_eng_role_id, 11, 2),  -- Decision Management
        (29, integ_eng_role_id, 12, 4),  -- Information Management
        (29, integ_eng_role_id, 13, 4),  -- Configuration Management
        (29, integ_eng_role_id, 14, 2),  -- Requirements Definition
        (29, integ_eng_role_id, 15, 4),  -- System Architecting
        (29, integ_eng_role_id, 16, 6),  -- Integration/Verification (expert)
        (29, integ_eng_role_id, 17, 4),  -- Operation Support
        (29, integ_eng_role_id, 18, 4);  -- Agile Methods

    RAISE NOTICE '[OK] Created % role-competency mappings', 64;
END $$;

-- ============================================================================
-- 4. Create Learning Strategies
-- ============================================================================
INSERT INTO learning_strategy (
    organization_id,
    strategy_name,
    strategy_description,
    selected,
    priority
) VALUES
    (29, 'Needs-based project-oriented training', 'Project-specific SE training tailored to organizational needs', true, 1),
    (29, 'SE for managers', 'Systems engineering fundamentals for management', true, 2),
    (29, 'Train the SE-trainer', 'Advanced training to develop internal SE trainers', false, 3);

-- ============================================================================
-- 5. Create Strategy-Competency Mappings (From templates)
-- ============================================================================
DO $$
DECLARE
    needs_based_id INTEGER;
    se_managers_id INTEGER;
    train_trainer_id INTEGER;
BEGIN
    SELECT id INTO needs_based_id FROM learning_strategy WHERE organization_id = 29 AND strategy_name = 'Needs-based project-oriented training';
    SELECT id INTO se_managers_id FROM learning_strategy WHERE organization_id = 29 AND strategy_name = 'SE for managers';
    SELECT id INTO train_trainer_id FROM learning_strategy WHERE organization_id = 29 AND strategy_name = 'Train the SE-trainer';

    -- Needs-based project-oriented training: targets level 4 (Apply)
    INSERT INTO strategy_competency (strategy_id, competency_id, target_level) VALUES
        (needs_based_id, 1, 4),   (needs_based_id, 4, 4),   (needs_based_id, 5, 4),
        (needs_based_id, 6, 4),   (needs_based_id, 7, 4),   (needs_based_id, 8, 2),
        (needs_based_id, 9, 4),   (needs_based_id, 10, 4),  (needs_based_id, 11, 4),
        (needs_based_id, 12, 4),  (needs_based_id, 13, 2),  (needs_based_id, 14, 4),
        (needs_based_id, 15, 4),  (needs_based_id, 16, 4),  (needs_based_id, 17, 2),
        (needs_based_id, 18, 2);

    -- SE for managers: targets level 2 (Understand)
    INSERT INTO strategy_competency (strategy_id, competency_id, target_level) VALUES
        (se_managers_id, 1, 4),   (se_managers_id, 4, 2),   (se_managers_id, 5, 2),
        (se_managers_id, 6, 2),   (se_managers_id, 7, 4),   (se_managers_id, 8, 4),
        (se_managers_id, 9, 2),   (se_managers_id, 10, 4),  (se_managers_id, 11, 4),
        (se_managers_id, 12, 2),  (se_managers_id, 13, 1),  (se_managers_id, 14, 1),
        (se_managers_id, 15, 1),  (se_managers_id, 16, 1),  (se_managers_id, 17, 1),
        (se_managers_id, 18, 1);

    -- Train the SE-trainer: targets level 6 (Mastery) - not selected but for reference
    INSERT INTO strategy_competency (strategy_id, competency_id, target_level) VALUES
        (train_trainer_id, 1, 6),   (train_trainer_id, 4, 6),   (train_trainer_id, 5, 6),
        (train_trainer_id, 6, 6),   (train_trainer_id, 7, 6),   (train_trainer_id, 8, 4),
        (train_trainer_id, 9, 6),   (train_trainer_id, 10, 4),  (train_trainer_id, 11, 6),
        (train_trainer_id, 12, 6),  (train_trainer_id, 13, 4),  (train_trainer_id, 14, 6),
        (train_trainer_id, 15, 6),  (train_trainer_id, 16, 6),  (train_trainer_id, 17, 4),
        (train_trainer_id, 18, 4);

    RAISE NOTICE '[OK] Created strategy-competency mappings for 3 strategies';
END $$;

-- ============================================================================
-- 6. Create Test Users (20 users)
-- ============================================================================
DO $$
DECLARE
    user_id INTEGER;
    role_ids INTEGER[];
    lead_se_role INTEGER;
    req_analyst_role INTEGER;
    arch_lead_role INTEGER;
    integ_eng_role INTEGER;
BEGIN
    -- Get role IDs
    SELECT id INTO lead_se_role FROM organization_roles WHERE organization_id = 29 AND role_name = 'Lead Systems Engineer';
    SELECT id INTO req_analyst_role FROM organization_roles WHERE organization_id = 29 AND role_name = 'Requirements Analyst';
    SELECT id INTO arch_lead_role FROM organization_roles WHERE organization_id = 29 AND role_name = 'Architecture Lead';
    SELECT id INTO integ_eng_role FROM organization_roles WHERE organization_id = 29 AND role_name = 'Integration Engineer';

    -- Create 20 users with role distribution:
    -- 6 Lead SE, 5 Req Analyst, 5 Arch Lead, 4 Integ Engineer

    -- Lead Systems Engineers (6 users)
    FOR i IN 1..6 LOOP
        INSERT INTO new_survey_user (username, email, organization_id, access_level)
        VALUES (
            'org29_lead_se_' || i,
            'lead.se.' || i || '@org29.test',
            29,
            'user'
        ) RETURNING id INTO user_id;

        -- Create assessment
        INSERT INTO user_assessment (user_id, organization_id, selected_roles, completed_at)
        VALUES (user_id, 29, jsonb_build_array(lead_se_role), NOW() - (i * interval '1 day'));
    END LOOP;

    -- Requirements Analysts (5 users)
    FOR i IN 1..5 LOOP
        INSERT INTO new_survey_user (username, email, organization_id, access_level)
        VALUES (
            'org29_req_analyst_' || i,
            'req.analyst.' || i || '@org29.test',
            29,
            'user'
        ) RETURNING id INTO user_id;

        INSERT INTO user_assessment (user_id, organization_id, selected_roles, completed_at)
        VALUES (user_id, 29, jsonb_build_array(req_analyst_role), NOW() - (i * interval '1 day'));
    END LOOP;

    -- Architecture Leads (5 users)
    FOR i IN 1..5 LOOP
        INSERT INTO new_survey_user (username, email, organization_id, access_level)
        VALUES (
            'org29_arch_lead_' || i,
            'arch.lead.' || i || '@org29.test',
            29,
            'user'
        ) RETURNING id INTO user_id;

        INSERT INTO user_assessment (user_id, organization_id, selected_roles, completed_at)
        VALUES (user_id, 29, jsonb_build_array(arch_lead_role), NOW() - (i * interval '1 day'));
    END LOOP;

    -- Integration Engineers (4 users)
    FOR i IN 1..4 LOOP
        INSERT INTO new_survey_user (username, email, organization_id, access_level)
        VALUES (
            'org29_integ_eng_' || i,
            'integ.eng.' || i || '@org29.test',
            29,
            'user'
        ) RETURNING id INTO user_id;

        INSERT INTO user_assessment (user_id, organization_id, selected_roles, completed_at)
        VALUES (user_id, 29, jsonb_build_array(integ_eng_role), NOW() - (i * interval '1 day'));
    END LOOP;

    RAISE NOTICE '[OK] Created 20 users with role assignments';
END $$;

-- ============================================================================
-- 7. Populate Competency Assessment Results (Varied Levels)
-- ============================================================================
-- This creates realistic scenario distribution with varied current levels
DO $$
DECLARE
    assessment_rec RECORD;
    competency_id INTEGER;
    score_value INTEGER;
    role_name TEXT;
BEGIN
    -- For each assessment
    FOR assessment_rec IN
        SELECT ua.id as assessment_id, ua.selected_roles, nsu.username
        FROM user_assessment ua
        JOIN new_survey_user nsu ON ua.user_id = nsu.id
        WHERE ua.organization_id = 29 AND ua.completed_at IS NOT NULL
    LOOP
        -- Get role name from username pattern
        role_name := CASE
            WHEN assessment_rec.username LIKE '%lead_se%' THEN 'Lead Systems Engineer'
            WHEN assessment_rec.username LIKE '%req_analyst%' THEN 'Requirements Analyst'
            WHEN assessment_rec.username LIKE '%arch_lead%' THEN 'Architecture Lead'
            WHEN assessment_rec.username LIKE '%integ_eng%' THEN 'Integration Engineer'
        END;

        -- Populate all 16 competencies with varied scores
        FOR competency_id IN 1..18 LOOP
            -- Skip if competency doesn't exist (competencies 2, 3 might not exist)
            CONTINUE WHEN competency_id IN (2, 3);

            -- Varied score distribution based on role and competency
            score_value := CASE
                -- Lead SE: generally high (3-4), some at 2
                WHEN role_name = 'Lead Systems Engineer' THEN
                    CASE
                        WHEN competency_id IN (6, 11, 15) THEN 4  -- Strong in key areas
                        WHEN competency_id IN (17, 18) THEN 2     -- Weaker in operations/agile
                        ELSE 3 + (RANDOM() * 1)::INTEGER          -- 3 or 4
                    END
                -- Req Analyst: strong in requirements (14), customer (5), moderate elsewhere
                WHEN role_name = 'Requirements Analyst' THEN
                    CASE
                        WHEN competency_id = 14 THEN 4            -- Strong requirements
                        WHEN competency_id = 5 THEN 4             -- Strong customer focus
                        WHEN competency_id IN (15, 16, 17) THEN 1 -- Weak in technical areas
                        ELSE 2 + (RANDOM() * 1)::INTEGER          -- 2 or 3
                    END
                -- Arch Lead: strong in architecting (15), modeling (6)
                WHEN role_name = 'Architecture Lead' THEN
                    CASE
                        WHEN competency_id IN (6, 15) THEN 4      -- Strong in key areas
                        WHEN competency_id IN (8, 10, 17) THEN 2  -- Moderate in management
                        ELSE 3 + (RANDOM() * 1)::INTEGER          -- 3 or 4
                    END
                -- Integ Engineer: strong in integration (16), operations (17)
                WHEN role_name = 'Integration Engineer' THEN
                    CASE
                        WHEN competency_id IN (16, 17, 18) THEN 4 -- Strong in integration/ops
                        WHEN competency_id IN (5, 8, 10) THEN 2   -- Weak in soft skills
                        ELSE 2 + (RANDOM() * 2)::INTEGER          -- 2-4
                    END
                ELSE 2  -- Default
            END;

            -- Insert score
            INSERT INTO user_se_competency_survey_results (
                assessment_id,
                competency_id,
                score,
                created_at
            ) VALUES (
                assessment_rec.assessment_id,
                competency_id,
                score_value,
                NOW() - (assessment_rec.assessment_id * interval '1 hour')
            );
        END LOOP;
    END LOOP;

    RAISE NOTICE '[OK] Populated competency assessment results for all users';
END $$;

-- ============================================================================
-- 8. Final Summary
-- ============================================================================
DO $$
DECLARE
    role_count INTEGER;
    strategy_count INTEGER;
    user_count INTEGER;
    assessment_count INTEGER;
    result_count INTEGER;
    maturity_level INTEGER;
BEGIN
    SELECT COUNT(*) INTO role_count FROM organization_roles WHERE organization_id = 29;
    SELECT COUNT(*) INTO strategy_count FROM learning_strategy WHERE organization_id = 29 AND selected = true;
    SELECT COUNT(*) INTO user_count FROM new_survey_user WHERE organization_id = 29;
    SELECT COUNT(*) INTO assessment_count FROM user_assessment WHERE organization_id = 29 AND completed_at IS NOT NULL;
    SELECT COUNT(*) INTO result_count FROM user_se_competency_survey_results WHERE assessment_id IN (
        SELECT id FROM user_assessment WHERE organization_id = 29
    );

    -- Get maturity level
    SELECT
        (responses->'results'->'strategyInputs'->>'seProcessesValue')::INTEGER
    INTO maturity_level
    FROM phase_questionnaire_responses
    WHERE organization_id = 29 AND questionnaire_type = 'maturity' AND phase = 1;

    RAISE NOTICE '========================================================================';
    RAISE NOTICE 'TEST DATA SUMMARY - ORGANIZATION 29 (HIGH MATURITY)';
    RAISE NOTICE '========================================================================';
    RAISE NOTICE 'Maturity Level: % (Triggers ROLE_BASED pathway)', maturity_level;
    RAISE NOTICE 'Roles: %', role_count;
    RAISE NOTICE 'Selected strategies: %', strategy_count;
    RAISE NOTICE 'Users created: %', user_count;
    RAISE NOTICE 'Completed assessments: %', assessment_count;
    RAISE NOTICE 'Competency scores: %', result_count;
    RAISE NOTICE '========================================================================';

    IF maturity_level >= 3 AND role_count >= 4 AND strategy_count >= 2 AND assessment_count >= 15 THEN
        RAISE NOTICE '[SUCCESS] Org 29 test data ready for role-based pathway testing!';
        RAISE NOTICE '[INFO] Expected pathway: ROLE_BASED (maturity_level = %, threshold = 3)', maturity_level;
    ELSE
        RAISE WARNING '[WARNING] Test data may be incomplete';
    END IF;
END $$;
