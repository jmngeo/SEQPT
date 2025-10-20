-- Clear all cached feedback to force regeneration with improved LLM prompt
-- This ensures all users will get the new, contextual feedback that:
-- 1. Shows "N/A" for improvement areas when competency is met
-- 2. Doesn't include percentage values
-- 3. Focuses on qualitative competency indicators

DELETE FROM user_competency_survey_feedback;

-- Verify deletion
SELECT COUNT(*) as remaining_feedback_entries FROM user_competency_survey_feedback;
