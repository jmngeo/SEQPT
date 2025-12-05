-- ============================================================================
-- Phase 2 Task 3 - Comprehensive Test Data
-- ============================================================================
-- Purpose: Create comprehensive test scenarios for all 10 test categories
-- Date: November 4, 2025
-- Categories: Maturity levels, completion rates, multi-role users, scenarios,
--             best-fit selection, validation, PMT, core competencies, APIs, edge cases
-- ============================================================================

-- Clean up existing test data (optional - comment out if you want to keep existing data)
-- DELETE FROM competency_score WHERE user_id IN (SELECT id FROM new_survey_user WHERE organization_id BETWEEN 100 AND 110);
-- DELETE FROM user_assessment WHERE organization_id BETWEEN 100 AND 110;
-- DELETE FROM phase_questionnaire_response WHERE organization_id BETWEEN 100 AND 110;
-- DELETE FROM learning_strategy WHERE organization_id BETWEEN 100 AND 110;
-- DELETE FROM role_competency_matrix WHERE organization_id BETWEEN 100 AND 110;
-- DELETE FROM organization_roles WHERE organization_id BETWEEN 100 AND 110;
-- DELETE FROM organization_pmt_context WHERE organization_id BETWEEN 100 AND 110;
-- DELETE FROM new_survey_user WHERE organization_id BETWEEN 100 AND 110;
-- DELETE FROM organization WHERE id BETWEEN 100 AND 110;

-- ============================================================================
-- TEST CATEGORY 1: MATURITY LEVELS (Organizations 100-106)
-- ============================================================================
-- Purpose: Test pathway determination based on different maturity levels

-- Org 100: Maturity Level 1 (Initial/Ad-hoc) → TASK_BASED
INSERT INTO organization (id, organization_name, organization_description, created_at)
VALUES (100, 'Tech Startup Inc', 'Low maturity - Initial processes', NOW());

INSERT INTO phase_questionnaire_response (organization_id, questionnaire_type, phase, completed_at, responses)
VALUES (100, 'maturity', 1, NOW(),
    '{"answers": {}, "results": {"strategyInputs": {"seProcessesValue": 1}}}'::jsonb
);

-- Org 101: Maturity Level 2 (Managed) → TASK_BASED
INSERT INTO organization (id, organization_name, organization_description, created_at)
VALUES (101, 'Growing Systems Co', 'Low maturity - Managed processes', NOW());

INSERT INTO phase_questionnaire_response (organization_id, questionnaire_type, phase, completed_at, responses)
VALUES (101, 'maturity', 1, NOW(),
    '{"answers": {}, "results": {"strategyInputs": {"seProcessesValue": 2}}}'::jsonb
);

-- Org 102: Maturity Level 3 (Defined) → ROLE_BASED (THRESHOLD)
INSERT INTO organization (id, organization_name, organization_description, created_at)
VALUES (102, 'Established Engineering Ltd', 'Medium maturity - Defined processes', NOW());

INSERT INTO phase_questionnaire_response (organization_id, questionnaire_type, phase, completed_at, responses)
VALUES (102, 'maturity', 1, NOW(),
    '{"answers": {}, "results": {"strategyInputs": {"seProcessesValue": 3}}}'::jsonb
);

-- Org 103: Maturity Level 4 (Quantitatively Managed) → ROLE_BASED
INSERT INTO organization (id, organization_name, organization_description, created_at)
VALUES (103, 'Advanced Systems Corp', 'High maturity - Quantitatively managed', NOW());

INSERT INTO phase_questionnaire_response (organization_id, questionnaire_type, phase, completed_at, responses)
VALUES (103, 'maturity', 1, NOW(),
    '{"answers": {}, "results": {"strategyInputs": {"seProcessesValue": 4}}}'::jsonb
);

-- Org 104: Maturity Level 5 (Optimizing) → ROLE_BASED
INSERT INTO organization (id, organization_name, organization_description, created_at)
VALUES (104, 'Elite Engineering GmbH', 'Very high maturity - Optimizing processes', NOW());

INSERT INTO phase_questionnaire_response (organization_id, questionnaire_type, phase, completed_at, responses)
VALUES (104, 'maturity', 1, NOW(),
    '{"answers": {}, "results": {"strategyInputs": {"seProcessesValue": 5}}}'::jsonb
);

-- Org 105: No Maturity Data (Should default to level 5 → ROLE_BASED)
INSERT INTO organization (id, organization_name, organization_description, created_at)
VALUES (105, 'No Maturity Assessment Co', 'No maturity assessment completed', NOW());
-- Note: No phase_questionnaire_response entry - tests default behavior

-- Org 106: Maturity 3+ but NO ROLES defined (Edge case - should warn)
INSERT INTO organization (id, organization_name, organization_description, created_at)
VALUES (106, 'High Maturity No Roles Inc', 'High maturity but no roles defined', NOW());

INSERT INTO phase_questionnaire_response (organization_id, questionnaire_type, phase, completed_at, responses)
VALUES (106, 'maturity', 1, NOW(),
    '{"answers": {}, "results": {"strategyInputs": {"seProcessesValue": 4}}}'::jsonb
);
-- Note: Intentionally no organization_roles entries - tests edge case

-- ============================================================================
-- TEST CATEGORY 2: COMPLETION RATES (Organization 107)
-- ============================================================================
-- Purpose: Test that NO automatic threshold enforcement exists (only fail at 0%)

INSERT INTO organization (id, organization_name, organization_description, created_at)
VALUES (107, 'Partial Assessment Corp', 'Testing various completion rates', NOW());

INSERT INTO phase_questionnaire_response (organization_id, questionnaire_type, phase, completed_at, responses)
VALUES (107, 'maturity', 1, NOW(),
    '{"answers": {}, "results": {"strategyInputs": {"seProcessesValue": 3}}}'::jsonb
);

-- Create 10 users (for testing various completion percentages)
INSERT INTO new_survey_user (id, username, organization_id, created_at)
VALUES
    (1070, 'completion_user_1', 107, NOW()),
    (1071, 'completion_user_2', 107, NOW()),
    (1072, 'completion_user_3', 107, NOW()),
    (1073, 'completion_user_4', 107, NOW()),
    (1074, 'completion_user_5', 107, NOW()),
    (1075, 'completion_user_6', 107, NOW()),
    (1076, 'completion_user_7', 107, NOW()),
    (1077, 'completion_user_8', 107, NOW()),
    (1078, 'completion_user_9', 107, NOW()),
    (1079, 'completion_user_10', 107, NOW());

-- Add roles for org 107
INSERT INTO organization_roles (id, organization_id, role_name, created_at)
VALUES
    (1070, 107, 'Systems Engineer', NOW()),
    (1071, 107, 'Test Engineer', NOW());

-- Test scenarios:
-- 0% completion: 0 users with assessments (should FAIL)
-- 10% completion: 1 user with assessment (should PASS - no threshold)
-- 30% completion: 3 users with assessments (should PASS)
-- 50% completion: 5 users with assessments (should PASS)
-- 69% completion: 7 users with assessments (should PASS - old would fail)
-- 70% completion: 7 users with assessments (should PASS)
-- 100% completion: 10 users with assessments (should PASS)

-- For now, create assessments for 3 users (30% completion)
INSERT INTO user_assessment (user_id, organization_id, survey_type, completed_at, created_at)
VALUES
    (1070, 107, 'known_roles', NOW(), NOW()),
    (1071, 107, 'known_roles', NOW(), NOW()),
    (1072, 107, 'known_roles', NOW(), NOW());

-- ============================================================================
-- TEST CATEGORY 3: MULTI-ROLE USERS (Organization 108)
-- ============================================================================
-- Purpose: Test multi-role user MAX requirement calculation

INSERT INTO organization (id, organization_name, organization_description, created_at)
VALUES (108, 'Multi-Role Testing Corp', 'Tests multi-role user scenarios', NOW());

INSERT INTO phase_questionnaire_response (organization_id, questionnaire_type, phase, completed_at, responses)
VALUES (108, 'maturity', 1, NOW(),
    '{"answers": {}, "results": {"strategyInputs": {"seProcessesValue": 4}}}'::jsonb
);

-- Create 3 roles with different competency requirements
INSERT INTO organization_roles (id, organization_id, role_name, created_at)
VALUES
    (1080, 108, 'Junior Engineer', NOW()),
    (1081, 108, 'Senior Engineer', NOW()),
    (1082, 108, 'Lead Engineer', NOW());

-- Define competency requirements for each role
-- Junior Engineer: Level 2 for most competencies
INSERT INTO role_competency_matrix (role_cluster_id, competency_id, role_competency_value, organization_id)
SELECT 1080, comp_id, 2, 108
FROM generate_series(1, 16) AS comp_id
WHERE comp_id NOT IN (1, 4, 5, 6); -- Skip core competencies

-- Senior Engineer: Level 4 for most competencies
INSERT INTO role_competency_matrix (role_cluster_id, competency_id, role_competency_value, organization_id)
SELECT 1081, comp_id, 4, 108
FROM generate_series(1, 16) AS comp_id
WHERE comp_id NOT IN (1, 4, 5, 6);

-- Lead Engineer: Level 6 for key competencies
INSERT INTO role_competency_matrix (role_cluster_id, competency_id, role_competency_value, organization_id)
SELECT 1082, comp_id, 6, 108
FROM generate_series(1, 16) AS comp_id
WHERE comp_id IN (7, 8, 10, 11, 14, 15); -- Leadership, Decision, Requirements, Architecting

-- Create users with different role combinations
INSERT INTO new_survey_user (id, username, organization_id, created_at)
VALUES
    (1080, 'single_role_junior', 108, NOW()),
    (1081, 'single_role_senior', 108, NOW()),
    (1082, 'multi_role_junior_senior', 108, NOW()),
    (1083, 'multi_role_all_three', 108, NOW());

-- Assign roles to users
-- User 1080: Single role (Junior)
UPDATE new_survey_user SET selected_role_ids = ARRAY[1080] WHERE id = 1080;

-- User 1081: Single role (Senior)
UPDATE new_survey_user SET selected_role_ids = ARRAY[1081] WHERE id = 1081;

-- User 1082: Multi-role (Junior + Senior) - should use MAX requirement
UPDATE new_survey_user SET selected_role_ids = ARRAY[1080, 1081] WHERE id = 1082;

-- User 1083: Multi-role (All three) - should use MAX requirement
UPDATE new_survey_user SET selected_role_ids = ARRAY[1080, 1081, 1082] WHERE id = 1083;

-- Create assessments
INSERT INTO user_assessment (user_id, organization_id, survey_type, completed_at, created_at)
VALUES
    (1080, 108, 'known_roles', NOW(), NOW()),
    (1081, 108, 'known_roles', NOW(), NOW()),
    (1082, 108, 'known_roles', NOW(), NOW()),
    (1083, 108, 'known_roles', NOW(), NOW());

-- Add competency scores (all at level 1 - below all role requirements)
INSERT INTO competency_score (user_id, competency_id, score, created_at)
SELECT user_id, comp_id, 1, NOW()
FROM generate_series(1080, 1083) AS user_id
CROSS JOIN generate_series(1, 16) AS comp_id;

-- ============================================================================
-- TEST CATEGORY 4: SCENARIO CLASSIFICATION (Organization 109)
-- ============================================================================
-- Purpose: Test all 4 scenarios (A, B, C, D) with real user examples

INSERT INTO organization (id, organization_name, organization_description, created_at)
VALUES (109, 'Scenario Testing Inc', 'Tests all gap scenarios', NOW());

INSERT INTO phase_questionnaire_response (organization_id, questionnaire_type, phase, completed_at, responses)
VALUES (109, 'maturity', 1, NOW(),
    '{"answers": {}, "results": {"strategyInputs": {"seProcessesValue": 4}}}'::jsonb
);

-- Create role
INSERT INTO organization_roles (id, organization_id, role_name, created_at)
VALUES (1090, 109, 'Test Role', NOW());

-- Set competency requirements
-- Communication (7): 4, Decision (11): 4, Requirements (14): 4
INSERT INTO role_competency_matrix (role_cluster_id, competency_id, role_competency_value, organization_id)
VALUES
    (1090, 7, 4, 109),  -- Communication: Level 4
    (1090, 11, 4, 109), -- Decision Management: Level 4
    (1090, 14, 4, 109), -- Requirements: Level 4
    (1090, 15, 2, 109); -- Architecting: Level 2

-- Add strategy with specific targets
INSERT INTO learning_strategy (organization_id, strategy_name, strategy_description, selected, priority, created_at)
VALUES (109, 'Foundation Workshop', 'Basic SE training', true, 1, NOW());

INSERT INTO strategy_competency (strategy_id, competency_id, target_level, created_at)
SELECT currval('learning_strategy_id_seq'), comp_id, 2, NOW()
FROM generate_series(1, 16) AS comp_id
WHERE comp_id IN (7, 11, 14, 15);

-- Create users representing each scenario
INSERT INTO new_survey_user (id, username, organization_id, selected_role_ids, created_at)
VALUES
    (1090, 'scenario_A_user', 109, ARRAY[1090], NOW()), -- Scenario A: current < archetype <= role
    (1091, 'scenario_B_user', 109, ARRAY[1090], NOW()), -- Scenario B: archetype <= current < role
    (1092, 'scenario_C_user', 109, ARRAY[1090], NOW()), -- Scenario C: archetype > role
    (1093, 'scenario_D_user', 109, ARRAY[1090], NOW()); -- Scenario D: current >= both

-- Create assessments
INSERT INTO user_assessment (user_id, organization_id, survey_type, completed_at, created_at)
VALUES
    (1090, 109, 'known_roles', NOW(), NOW()),
    (1091, 109, 'known_roles', NOW(), NOW()),
    (1092, 109, 'known_roles', NOW(), NOW()),
    (1093, 109, 'known_roles', NOW(), NOW());

-- Competency scores for scenario testing (Communication ID=7)
-- Scenario A: current=0, archetype=2, role=4 → A (current < archetype <= role)
INSERT INTO competency_score (user_id, competency_id, score) VALUES (1090, 7, 0);

-- Scenario B: current=2, archetype=2, role=4 → B (archetype <= current < role)
INSERT INTO competency_score (user_id, competency_id, score) VALUES (1091, 7, 2);

-- Scenario C: current=0, archetype=4, role=2 → C (archetype > role) [using Architecting instead]
INSERT INTO competency_score (user_id, competency_id, score) VALUES (1092, 15, 0);

-- Scenario D: current=4, archetype=2, role=4 → D (current >= both)
INSERT INTO competency_score (user_id, competency_id, score) VALUES (1093, 7, 4);

-- ============================================================================
-- TEST CATEGORY 5: PMT CUSTOMIZATION (Organization 110)
-- ============================================================================
-- Purpose: Test PMT-based deep customization for specific strategies

INSERT INTO organization (id, organization_name, organization_description, created_at)
VALUES (110, 'PMT Customization Corp', 'Tests PMT context system', NOW());

INSERT INTO phase_questionnaire_response (organization_id, questionnaire_type, phase, completed_at, responses)
VALUES (110, 'maturity', 1, NOW(),
    '{"answers": {}, "results": {"strategyInputs": {"seProcessesValue": 4}}}'::jsonb
);

-- Add PMT context
INSERT INTO organization_pmt_context (organization_id, processes, methods, tools, industry, created_at)
VALUES (110,
    'ISO 26262 for automotive safety, V-model for system development, Agile for software development',
    'Requirements traceability, Trade-off analysis, Risk-based testing',
    'DOORS for requirements management, JIRA for project tracking, Enterprise Architect for SysML modeling, Git for version control',
    'Automotive embedded systems - ADAS and autonomous driving',
    NOW()
);

-- Add strategies requiring PMT (deep customization)
INSERT INTO learning_strategy (organization_id, strategy_name, strategy_description, selected, priority, created_at)
VALUES
    (110, 'Needs-based project-oriented training', 'Project-based deep training', true, 1, NOW()),
    (110, 'Continuous support', 'Ongoing coaching and support', true, 2, NOW());

-- Add strategy targets
INSERT INTO strategy_competency (strategy_id, competency_id, target_level, created_at)
SELECT s.id, comp_id, 4, NOW()
FROM learning_strategy s
CROSS JOIN generate_series(1, 16) AS comp_id
WHERE s.organization_id = 110 AND comp_id NOT IN (1, 4, 5, 6);

-- Create role and users
INSERT INTO organization_roles (id, organization_id, role_name, created_at)
VALUES (1100, 110, 'Automotive Systems Engineer', NOW());

INSERT INTO role_competency_matrix (role_cluster_id, competency_id, role_competency_value, organization_id)
SELECT 1100, comp_id, 4, 110
FROM generate_series(1, 16) AS comp_id
WHERE comp_id NOT IN (1, 4, 5, 6);

INSERT INTO new_survey_user (id, username, organization_id, selected_role_ids, created_at)
VALUES
    (1100, 'pmt_test_user_1', 110, ARRAY[1100], NOW()),
    (1101, 'pmt_test_user_2', 110, ARRAY[1100], NOW());

INSERT INTO user_assessment (user_id, organization_id, survey_type, completed_at, created_at)
VALUES
    (1100, 110, 'known_roles', NOW(), NOW()),
    (1101, 110, 'known_roles', NOW(), NOW());

-- Add scores (level 2 - below target 4)
INSERT INTO competency_score (user_id, competency_id, score, created_at)
SELECT user_id, comp_id, 2, NOW()
FROM generate_series(1100, 1101) AS user_id
CROSS JOIN generate_series(1, 16) AS comp_id
WHERE comp_id NOT IN (1, 4, 5, 6);

-- ============================================================================
-- SUMMARY OF TEST DATA
-- ============================================================================

/*
TEST CATEGORIES CREATED:

Category 1: Maturity Levels (Orgs 100-106)
- Org 100: Maturity 1 → TASK_BASED
- Org 101: Maturity 2 → TASK_BASED
- Org 102: Maturity 3 → ROLE_BASED (threshold)
- Org 103: Maturity 4 → ROLE_BASED
- Org 104: Maturity 5 → ROLE_BASED
- Org 105: No maturity → Default to 5 (ROLE_BASED)
- Org 106: Maturity 4 but no roles → Edge case

Category 2: Completion Rates (Org 107)
- 10 users created
- 3 assessments (30% completion) - can adjust for testing
- Tests: 0%, 10%, 30%, 50%, 69%, 70%, 100%

Category 3: Multi-Role Users (Org 108)
- 4 users: single-role, multi-role (2), multi-role (3)
- Tests MAX requirement calculation

Category 4: Scenario Classification (Org 109)
- 4 users representing scenarios A, B, C, D
- Tests 3-way comparison logic

Category 5: PMT Customization (Org 110)
- Complete PMT context defined
- 2 strategies requiring deep customization
- Tests LLM integration

NEXT STEPS:
1. Run SQL script to populate database
2. Execute test scripts (Python) to validate
3. Document results

TESTING COMMANDS:
-- Check organizations created:
SELECT id, organization_name, organization_description
FROM organization WHERE id BETWEEN 100 AND 110 ORDER BY id;

-- Check maturity levels:
SELECT o.id, o.organization_name,
       (p.responses->'results'->'strategyInputs'->>'seProcessesValue')::int AS maturity_level
FROM organization o
LEFT JOIN phase_questionnaire_response p ON o.id = p.organization_id AND p.questionnaire_type = 'maturity'
WHERE o.id BETWEEN 100 AND 110
ORDER BY o.id;

-- Check completion rates:
SELECT o.id, o.organization_name,
       COUNT(DISTINCT u.id) AS total_users,
       COUNT(DISTINCT ua.user_id) AS users_with_assessments,
       ROUND(COUNT(DISTINCT ua.user_id)::numeric / NULLIF(COUNT(DISTINCT u.id), 0) * 100, 1) AS completion_rate
FROM organization o
LEFT JOIN new_survey_user u ON o.id = u.organization_id
LEFT JOIN user_assessment ua ON u.id = ua.user_id AND ua.completed_at IS NOT NULL
WHERE o.id = 107
GROUP BY o.id, o.organization_name;
*/
