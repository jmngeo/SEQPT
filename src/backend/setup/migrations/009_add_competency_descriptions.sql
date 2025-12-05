-- Migration 009: Add English descriptions to all 16 SE competencies
-- Date: 2025-11-15
-- Purpose: Populate the description field for all competencies with English translations
--          from the German SE4OWL competency framework (SE_Kompetenzen_SE4OWL Excel sheet)
--
-- Usage: PGPASSWORD=SeQpt_2025 psql -h localhost -U seqpt_admin -d seqpt_database -f 009_add_competency_descriptions.sql
--
-- Note: This migration is idempotent - safe to run multiple times

-- Core Competencies
UPDATE competency SET description = 'The ability to apply fundamental concepts of systems thinking in Systems Engineering and understand the role of one''s own system in its overall context.'
WHERE competency_name = 'Systems Thinking';

UPDATE competency SET description = 'The ability to consider all lifecycle phases (except the operational phase) in system requirements, architectures, and designs during system development.'
WHERE competency_name = 'Lifecycle Consideration';

UPDATE competency SET description = 'The ability to place agile values and customer benefits at the center of development.'
WHERE competency_name = 'Customer / Value Orientation';

UPDATE competency SET description = 'The ability to provide precise data and information using cross-domain models to support technical understanding and decision-making.'
WHERE competency_name = 'Systems Modelling and Analysis';

-- Social / Personal Competencies
UPDATE competency SET description = 'The ability to communicate constructively, efficiently, and consciously across domains, while capturing and considering the feelings of others and maintaining sustainable and fair relationships with colleagues and supervisors.'
WHERE competency_name = 'Communication';

UPDATE competency SET description = 'The ability to select appropriate goals for a system or system element, negotiate when necessary, and efficiently achieve them with a team while guiding team members in problem-solving when needed.'
WHERE competency_name = 'Leadership';

UPDATE competency SET description = 'The ability to organize oneself and manage tasks independently.'
WHERE competency_name = 'Self-Organization';

-- Management Competencies
UPDATE competency SET description = 'The ability to identify, plan, coordinate, and adapt activities to deliver a satisfactory system, product, or service with appropriate quality, budget, and timeline.'
WHERE competency_name = 'Project Management';

UPDATE competency SET description = 'The ability to identify, characterize, and evaluate an objective set of alternatives in a structured and analytical manner while considering risks and opportunities.'
WHERE competency_name = 'Decision Management';

UPDATE competency SET description = 'The ability to address all aspects of information for specific stakeholders to deliver the right information at the right time with appropriate security.'
WHERE competency_name = 'Information Management';

UPDATE competency SET description = 'The ability to consistently design system functions, performance, and physical properties across the lifecycle and ensure consistency.'
WHERE competency_name = 'Configuration Management';

-- Technical Competencies
UPDATE competency SET description = 'The ability to analyze stakeholder needs and expectations and derive system requirements from them.'
WHERE competency_name = 'Requirements Definition';

UPDATE competency SET description = 'The ability to define system-related elements, their hierarchy, interfaces, behavior, and associated derived requirements to develop an implementable solution.'
WHERE competency_name = 'System Architecting';

UPDATE competency SET description = 'The ability to integrate a set of system elements into a verifiable or validatable unit, and provide objective evidence that a system meets specified requirements (verification) or achieves its intended properties in the intended operational environment (validation).'
WHERE competency_name = 'Integration, Verification, Validation';

UPDATE competency SET description = 'The ability to commission, operate, and maintain a system''s capabilities and functionalities throughout its lifetime.'
WHERE competency_name = 'Operation and Support';

UPDATE competency SET description = 'The ability to apply methods that support agile values in the project context and enable parallel work.'
WHERE competency_name = 'Agile Methods';

-- Verify the updates
SELECT id, competency_name, LEFT(description, 80) as description_preview
FROM competency
ORDER BY id;
