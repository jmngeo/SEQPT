-- ============================================================================
-- SE-QPT Database Schema Unification
-- Extends Derik's tables for SE-QPT functionality
-- Date: 2025-10-01
-- ============================================================================

-- ============================================================================
-- 1. EXTEND ORGANIZATION TABLE (Phase 1 Support)
-- ============================================================================
ALTER TABLE organization
  ADD COLUMN IF NOT EXISTS size VARCHAR(20),
  ADD COLUMN IF NOT EXISTS maturity_score FLOAT,
  ADD COLUMN IF NOT EXISTS selected_archetype VARCHAR(100),
  ADD COLUMN IF NOT EXISTS phase1_completed BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();

-- Add comments
COMMENT ON COLUMN organization.size IS 'Organization size: small, medium, large, enterprise';
COMMENT ON COLUMN organization.maturity_score IS 'Overall maturity score from Phase 1 assessment (0-5)';
COMMENT ON COLUMN organization.selected_archetype IS 'Selected qualification archetype from Phase 1';
COMMENT ON COLUMN organization.phase1_completed IS 'Whether Phase 1 (maturity + archetype) is complete';

-- Create index for phase1_completed queries
CREATE INDEX IF NOT EXISTS idx_organization_phase1
  ON organization(phase1_completed);

-- ============================================================================
-- 2. EXTEND SURVEY RESULTS TABLE (Gap Analysis Support)
-- ============================================================================
ALTER TABLE user_se_competency_survey_results
  ADD COLUMN IF NOT EXISTS target_level INTEGER,
  ADD COLUMN IF NOT EXISTS gap_size INTEGER,
  ADD COLUMN IF NOT EXISTS archetype_source VARCHAR(100),
  ADD COLUMN IF NOT EXISTS learning_plan_id VARCHAR(36);

-- Add comments
COMMENT ON COLUMN user_se_competency_survey_results.target_level IS 'Target competency level from archetype matrix';
COMMENT ON COLUMN user_se_competency_survey_results.gap_size IS 'Calculated gap: target_level - score';
COMMENT ON COLUMN user_se_competency_survey_results.archetype_source IS 'Which archetype defined the target level';
COMMENT ON COLUMN user_se_competency_survey_results.learning_plan_id IS 'Link to generated learning plan';

-- Create indexes for gap queries
CREATE INDEX IF NOT EXISTS idx_survey_results_gaps
  ON user_se_competency_survey_results(user_id, gap_size);

CREATE INDEX IF NOT EXISTS idx_survey_results_archetype
  ON user_se_competency_survey_results(archetype_source);

-- ============================================================================
-- 3. CREATE LEARNING PLANS TABLE (SE-QPT Innovation)
-- ============================================================================
CREATE TABLE IF NOT EXISTS learning_plans (
  id VARCHAR(36) PRIMARY KEY,
  user_id INTEGER NOT NULL,
  organization_id INTEGER NOT NULL,

  -- Learning objectives (RAG-LLM generated, JSON format)
  objectives TEXT NOT NULL,

  -- Recommended modules (JSON array)
  recommended_modules TEXT,

  -- Plan metadata
  estimated_duration_weeks INTEGER,
  archetype_used VARCHAR(100),

  -- Timestamps
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  -- Foreign keys
  CONSTRAINT fk_learning_plan_user
    FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE CASCADE,
  CONSTRAINT fk_learning_plan_org
    FOREIGN KEY (organization_id) REFERENCES organization(id) ON DELETE CASCADE
);

-- Add comments
COMMENT ON TABLE learning_plans IS 'SE-QPT generated learning plans with SMART objectives';
COMMENT ON COLUMN learning_plans.objectives IS 'JSON array of SMART learning objectives';
COMMENT ON COLUMN learning_plans.recommended_modules IS 'JSON array of recommended learning modules';

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_learning_plans_user
  ON learning_plans(user_id);

CREATE INDEX IF NOT EXISTS idx_learning_plans_org
  ON learning_plans(organization_id);

CREATE INDEX IF NOT EXISTS idx_learning_plans_archetype
  ON learning_plans(archetype_used);

-- ============================================================================
-- 4. CREATE QUESTIONNAIRE RESPONSES TABLE (All Phases)
-- ============================================================================
CREATE TABLE IF NOT EXISTS questionnaire_responses (
  id VARCHAR(36) PRIMARY KEY,
  user_id INTEGER NOT NULL,
  organization_id INTEGER NOT NULL,

  -- Questionnaire metadata
  questionnaire_type VARCHAR(50) NOT NULL,  -- 'maturity', 'archetype_selection', etc.
  phase INTEGER NOT NULL,                   -- 1, 2, 3, 4

  -- Response data (JSON format)
  responses TEXT NOT NULL,
  computed_scores TEXT,  -- JSON: calculated scores/results

  -- Timestamps
  completed_at TIMESTAMP DEFAULT NOW(),

  -- Foreign keys
  CONSTRAINT fk_questionnaire_user
    FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE CASCADE,
  CONSTRAINT fk_questionnaire_org
    FOREIGN KEY (organization_id) REFERENCES organization(id) ON DELETE CASCADE
);

-- Add comments
COMMENT ON TABLE questionnaire_responses IS 'Store all questionnaire responses across phases';
COMMENT ON COLUMN questionnaire_responses.questionnaire_type IS 'Type: maturity, archetype_selection, role_mapping, etc.';
COMMENT ON COLUMN questionnaire_responses.responses IS 'JSON: raw questionnaire responses';
COMMENT ON COLUMN questionnaire_responses.computed_scores IS 'JSON: calculated scores from responses';

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_questionnaire_user
  ON questionnaire_responses(user_id);

CREATE INDEX IF NOT EXISTS idx_questionnaire_org
  ON questionnaire_responses(organization_id);

CREATE INDEX IF NOT EXISTS idx_questionnaire_phase
  ON questionnaire_responses(phase);

CREATE INDEX IF NOT EXISTS idx_questionnaire_type
  ON questionnaire_responses(questionnaire_type);

-- ============================================================================
-- 5. ADD FOREIGN KEY FROM SURVEY RESULTS TO LEARNING PLANS
-- ============================================================================
ALTER TABLE user_se_competency_survey_results
  ADD CONSTRAINT IF NOT EXISTS fk_survey_learning_plan
    FOREIGN KEY (learning_plan_id) REFERENCES learning_plans(id) ON DELETE SET NULL;

-- ============================================================================
-- 6. CREATE VIEW FOR COMPLETE USER ASSESSMENT DATA
-- ============================================================================
CREATE OR REPLACE VIEW v_user_complete_assessment AS
SELECT
  u.id as user_id,
  u.username,
  o.id as organization_id,
  o.organization_name,
  o.selected_archetype,
  o.maturity_score,
  c.id as competency_id,
  c.competency_name,
  c.competency_area,
  s.score as current_level,
  s.target_level,
  s.gap_size,
  s.archetype_source,
  s.submitted_at,
  lp.id as learning_plan_id,
  lp.objectives,
  lp.estimated_duration_weeks
FROM app_user u
  INNER JOIN organization o ON u.organization_id = o.id
  LEFT JOIN user_se_competency_survey_results s ON s.user_id = u.id
  LEFT JOIN competency c ON c.id = s.competency_id
  LEFT JOIN learning_plans lp ON lp.id = s.learning_plan_id;

COMMENT ON VIEW v_user_complete_assessment IS 'Complete view of user assessment data including gaps and learning plans';

-- ============================================================================
-- 7. VERIFICATION QUERIES
-- ============================================================================

-- Verify organization table structure
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'organization'
ORDER BY ordinal_position;

-- Verify survey results table structure
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'user_se_competency_survey_results'
ORDER BY ordinal_position;

-- Verify new tables created
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('learning_plans', 'questionnaire_responses');

-- Count existing data
SELECT
  'organization' as table_name, COUNT(*) as row_count FROM organization
UNION ALL
SELECT 'competency', COUNT(*) FROM competency
UNION ALL
SELECT 'role_cluster', COUNT(*) FROM role_cluster
UNION ALL
SELECT 'user_se_competency_survey_results', COUNT(*) FROM user_se_competency_survey_results
UNION ALL
SELECT 'learning_plans', COUNT(*) FROM learning_plans
UNION ALL
SELECT 'questionnaire_responses', COUNT(*) FROM questionnaire_responses;
