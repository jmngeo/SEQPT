-- Fix ALL process names to match Derik's data (removing ' process' suffix for cleaner names)
-- Based on sesurveyapp/postgres-init/init.sql

UPDATE iso_processes SET name = 'Acquisition' WHERE id = 1;
UPDATE iso_processes SET name = 'Supply' WHERE id = 2;
UPDATE iso_processes SET name = 'Life Cycle Model Management' WHERE id = 3;
UPDATE iso_processes SET name = 'Infrastructure Management' WHERE id = 4;
UPDATE iso_processes SET name = 'Portfolio Management' WHERE id = 5;
UPDATE iso_processes SET name = 'Human Resource Management' WHERE id = 6;
UPDATE iso_processes SET name = 'Quality Management' WHERE id = 7;
UPDATE iso_processes SET name = 'Knowledge Management' WHERE id = 8;
UPDATE iso_processes SET name = 'Project Planning' WHERE id = 9;
UPDATE iso_processes SET name = 'Project Assessment and Control' WHERE id = 10;
UPDATE iso_processes SET name = 'Decision Management' WHERE id = 11;
UPDATE iso_processes SET name = 'Risk Management' WHERE id = 12;
UPDATE iso_processes SET name = 'Configuration Management' WHERE id = 13;
UPDATE iso_processes SET name = 'Information Management' WHERE id = 14;
UPDATE iso_processes SET name = 'Measurement' WHERE id = 15;
UPDATE iso_processes SET name = 'Quality Assurance' WHERE id = 16;
UPDATE iso_processes SET name = 'Business or Mission Analysis' WHERE id = 17;
UPDATE iso_processes SET name = 'Stakeholder Needs and Requirements Definition' WHERE id = 18;
UPDATE iso_processes SET name = 'System Requirements Definition' WHERE id = 19;
UPDATE iso_processes SET name = 'System Architecture Definition' WHERE id = 20;
UPDATE iso_processes SET name = 'Design Definition' WHERE id = 21;
UPDATE iso_processes SET name = 'System Analysis' WHERE id = 22;
UPDATE iso_processes SET name = 'Implementation' WHERE id = 23;
UPDATE iso_processes SET name = 'Integration' WHERE id = 24;
UPDATE iso_processes SET name = 'Verification' WHERE id = 25;
UPDATE iso_processes SET name = 'Transition' WHERE id = 26;
UPDATE iso_processes SET name = 'Validation' WHERE id = 27;
UPDATE iso_processes SET name = 'Operation' WHERE id = 28;
UPDATE iso_processes SET name = 'Maintenance' WHERE id = 29;
UPDATE iso_processes SET name = 'Disposal' WHERE id = 30;

-- Verify
SELECT id, name FROM iso_processes ORDER BY id;
SELECT COUNT(*) as total, COUNT(DISTINCT name) as unique_names FROM iso_processes;
