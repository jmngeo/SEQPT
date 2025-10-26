# SE-QPT Backend Setup Guide

## Overview

This folder contains all scripts necessary to set up the SE-QPT system in a new environment. These scripts populate the database with reference data, create database objects (stored procedures), and initialize UI data.

---

## Quick Start (New Environment Setup)

### Prerequisites

- PostgreSQL 12+ installed and running
- Python 3.9+ with virtual environment activated
- Database credentials ready (`seqpt_admin:SeQpt_2025` or `postgres:root`)

### Complete Setup (Recommended)

Run these commands in order:

```bash
# 1. Navigate to backend directory
cd src/backend

# 2. Set up database and permissions
cd setup/core
python init_db_as_postgres.py
python create_user_and_grant.py
python grant_permissions.py

# 3. Create database schema (run Flask migrations)
cd ../..
python run.py  # Creates tables from models.py

# 4. Populate ALL reference data (Master Script)
cd setup/populate
python initialize_all_data.py

# 5. Create stored procedures
cd ../database_objects
python create_stored_procedures.py
python create_competency_feedback_stored_procedures.py

# 6. Initialize UI data (optional - for full system)
cd ../ui_data
python init_questionnaire_data.py
python init_module_library.py

# 7. Create test user for development (optional)
cd ../utils
python create_test_user.py
```

**Estimated time**: 5-10 minutes

---

## Folder Structure

```
setup/
├── README.md                    # This file
├── core/                        # Database & user setup
│   ├── init_db_as_postgres.py  # Initialize database as postgres superuser
│   ├── setup_database.py       # Alternative database setup
│   ├── create_user_and_grant.py # Create seqpt_admin user
│   ├── grant_permissions.py    # Grant database permissions
│   └── fix_schema_permissions.py # Fix schema permissions (if needed)
│
├── populate/                    # Reference data population
│   ├── initialize_all_data.py  # ⭐ MASTER SCRIPT - Runs all population in order
│   ├── populate_iso_processes.py
│   ├── populate_competencies.py
│   ├── populate_competency_indicators.py
│   ├── populate_roles_and_matrices.py
│   ├── populate_process_competency_matrix.py
│   ├── add_14_roles.py
│   ├── add_derik_process_tables.py
│   └── align_iso_processes.py
│
├── database_objects/            # Stored procedures & database functions
│   ├── create_stored_procedures.py
│   ├── create_competency_feedback_stored_procedures.py
│   ├── create_competency_indicators_table.py
│   └── create_role_competency_matrix.py
│
├── ui_data/                     # UI/frontend initialization
│   ├── init_questionnaire_data.py
│   ├── init_module_library.py
│   ├── update_complete_questionnaires.py
│   └── update_real_questions.py
│
├── reference/                   # Reference data updates
│   ├── extract_role_descriptions.py
│   ├── update_frontend_role_descriptions.py
│   └── update_brief_role_descriptions.py
│
└── utils/                       # Utilities
    ├── backup_database.py       # Database backup utility
    ├── create_test_user.py      # Create test user
    ├── rename_database.py       # Database rename utility
    └── drop_all_tables.py       # ⚠️ DANGEROUS - Drops all tables
```

---

## Step-by-Step Setup Guide

### Step 1: Database Setup

**Option A: Using postgres superuser** (Recommended)

```bash
cd setup/core
python init_db_as_postgres.py
```

This creates:
- Database: `seqpt_database`
- User: `seqpt_admin` with password `SeQpt_2025`
- Grants all necessary permissions

**Option B: Manual setup**

```bash
# As postgres user
psql -U postgres
CREATE DATABASE seqpt_database;
CREATE USER seqpt_admin WITH PASSWORD 'SeQpt_2025';
GRANT ALL PRIVILEGES ON DATABASE seqpt_database TO seqpt_admin;
```

Then run:
```bash
python create_user_and_grant.py
python grant_permissions.py
```

---

### Step 2: Create Database Schema

```bash
# From src/backend/
python run.py
```

This uses Flask-Migrate to create all tables defined in `models.py`:
- Organization tables
- Competency tables (16 competencies)
- Role tables (14 SE role clusters)
- ISO Process tables (30 processes)
- Matrix tables (role-process, process-competency, role-competency)
- User tables
- Assessment tables
- And more...

---

### Step 3: Populate Reference Data

**Master Script (Easiest)**:

```bash
cd setup/populate
python initialize_all_data.py
```

This populates:
✅ **30 ISO/IEC 15288 System Engineering Processes**
✅ **16 SE Competencies** (INCOSE framework)
✅ **14 SE Role Clusters** (from research)
✅ **Competency Behavioral Indicators** (4 proficiency levels)
✅ **Global Process-Competency Matrix** (mapping processes to competencies)
✅ **Default Role-Process Matrices** (organization 1 default values)
✅ **Default Role-Competency Matrices** (calculated from matrices)

**Manual Alternative** (Run scripts individually):

```bash
cd setup/populate

# 1. ISO Processes (30 processes across 4 groups)
python populate_iso_processes.py

# 2. Competencies (16 SE competencies)
python populate_competencies.py

# 3. Competency Indicators (behavioral indicators for each competency)
python populate_competency_indicators.py

# 4. Roles and Default Matrices (14 SE roles)
python populate_roles_and_matrices.py

# 5. Process-Competency Matrix (global mapping)
python populate_process_competency_matrix.py
```

---

### Step 4: Create Stored Procedures

```bash
cd setup/database_objects
python create_stored_procedures.py
python create_competency_feedback_stored_procedures.py
```

**What this creates**:

Stored procedures are pre-compiled SQL functions that live in PostgreSQL:

1. **`update_role_competency_matrix(org_id)`**
   - Calculates role-competency values from role-process × process-competency matrices
   - Called when organization customizes role-process mappings

2. **`update_unknown_role_competency_values(username, org_id)`**
   - Calculates competency requirements for task-based role mapping
   - Called after user completes task description in Phase 1

3. **`insert_new_org_default_role_process_matrix(org_id)`**
   - Copies default role-process matrix for new organizations
   - Called when new organization is created

4. **`generate_competency_feedback(...)`**
   - Generates LLM-based feedback for competency assessments
   - Called after Phase 2 competency assessment completion

---

### Step 5: Initialize UI Data (Optional)

```bash
cd setup/ui_data
python init_questionnaire_data.py  # Phase 1 maturity questionnaire
python init_module_library.py      # Learning modules for Phase 3/4
```

**Note**: Only needed if using the full questionnaire system or learning modules.

---

### Step 6: Create Test User (Development Only)

```bash
cd setup/utils
python create_test_user.py
```

Creates a test user for development:
- Username: `testuser`
- Password: `testpass`
- Organization: Test organization

---

## Verification

After setup, verify the database is populated:

```bash
# Check database connection
psql -U seqpt_admin -d seqpt_database -c "\dt"

# Count records in key tables
psql -U seqpt_admin -d seqpt_database -c "
SELECT
    'competency' as table_name, COUNT(*) as count FROM competency
UNION ALL
SELECT 'role_cluster', COUNT(*) FROM role_cluster
UNION ALL
SELECT 'iso_processes', COUNT(*) FROM iso_processes
UNION ALL
SELECT 'process_competency_matrix', COUNT(*) FROM process_competency_matrix;
"
```

**Expected Counts**:
- Competencies: **16**
- Role Clusters: **14**
- ISO Processes: **30**
- Process-Competency Matrix: **~400-500** entries

---

## Database Utilities

### Backup Database

```bash
cd setup/utils
python backup_database.py
```

Creates timestamped backup in `backups/` folder.

### Rename Database

```bash
cd setup/utils
# Edit rename_database.py to set old and new names
python rename_database.py
```

### Reset Database ⚠️ DANGEROUS

```bash
cd setup/utils
python drop_all_tables.py
```

**WARNING**: This deletes ALL data! Use only for complete reset.

---

## Troubleshooting

### Issue: Permission denied

**Solution**: Run as postgres superuser or check `grant_permissions.py`

```bash
psql -U postgres -d seqpt_database -c "
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO seqpt_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO seqpt_admin;
"
```

### Issue: Tables already exist

**Solution**: Either:
1. Skip table creation
2. Or drop and recreate: `python setup/utils/drop_all_tables.py`

### Issue: Import errors

**Solution**: Ensure you're in the backend directory and virtual environment is activated:

```bash
cd src/backend
source ../../venv/bin/activate  # Linux/Mac
../../venv/Scripts/activate      # Windows
```

### Issue: Database connection fails

**Solution**: Check `.env` file has correct `DATABASE_URL`:

```env
DATABASE_URL=postgresql://seqpt_admin:SeQpt_2025@localhost:5432/seqpt_database
```

---

## Environment Variables

Required in `src/backend/.env`:

```env
# Database
DATABASE_URL=postgresql://seqpt_admin:SeQpt_2025@localhost:5432/seqpt_database

# Flask
FLASK_APP=run.py
FLASK_DEBUG=1
SECRET_KEY=your-secret-key-here
JWT_SECRET_KEY=your-jwt-secret-here

# OpenAI (for LLM features)
OPENAI_API_KEY=your-openai-api-key-here
```

---

## Next Steps

After setup is complete:

1. **Start the backend server**:
   ```bash
   cd src/backend
   python run.py
   ```
   Server runs on `http://localhost:5000`

2. **Start the frontend**:
   ```bash
   cd src/frontend
   npm install
   npm run dev
   ```
   Frontend runs on `http://localhost:5173`

3. **Register first admin**:
   - Navigate to `http://localhost:5173/register-admin`
   - Create organization and admin account
   - Start using SE-QPT!

---

## Reference Data Details

### ISO/IEC 15288 Processes (30 processes)

4 Process Groups:
1. **Agreement Processes** (2 processes)
2. **Organizational Project-Enabling Processes** (8 processes)
3. **Technical Management Processes** (8 processes)
4. **Technical Processes** (12 processes)

### SE Competencies (16 competencies)

Based on INCOSE SE Competency Framework:
- Core competencies
- Technical competencies
- Management competencies
- Social competencies

### SE Role Clusters (14 roles)

From SE qualification research:
1. System Engineer
2. Requirements Engineer
3. System Architect
4. Design Engineer
5. Integration & Verification Engineer
6. Validation Engineer
7. Configuration Manager
8. Project Manager SE
9. Product Owner SE
10. Quality Engineer/Manager
11. Service Technician
12. Specialist Developer
13. Internal Support
14. External Partner

---

## Support

For issues or questions:
- Check SESSION_HANDOVER.md for latest system state
- Review CLEANUP_PLAN_REVISED.md for codebase organization
- Consult models.py for database schema details

---

**Last Updated**: 2025-10-25
**Maintained By**: SE-QPT Development Team
