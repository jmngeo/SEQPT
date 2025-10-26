# SE-QPT Backend Setup Guide

## Quick Start (New Machine)

### Option 1: Automated Setup (Recommended)
```bash
cd src/backend
python setup_database.py
```

This will:
1. ✓ Create PostgreSQL database
2. ✓ Create database user
3. ✓ Run migrations (create tables)
4. ✓ Run `initialize_all_data.py` automatically
5. ✓ Populate ALL required data

**Important**: When prompted "Run master data initialization now?", answer **YES**!

---

### Option 2: Manual Setup (If automated fails)
```bash
cd src/backend

# Step 1: Set database connection
set DATABASE_URL=postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment

# Step 2: Create tables (if not already done)
python init_db_as_postgres.py

# Step 3: Run master initialization script
python initialize_all_data.py
```

---

## What Gets Initialized

The `initialize_all_data.py` script populates:

| Data | Count | Scope | Purpose |
|------|-------|-------|---------|
| ISO Processes | 28 | Global | ISO/IEC 15288 process definitions |
| SE Competencies | 16 | Global | INCOSE competency framework |
| Role Clusters | 14 | Global | SE role definitions |
| Role-Process Matrix (Org 1) | 392 | Org 1 | **TEMPLATE** for new organizations |
| Process-Competency Matrix | 448 | Global | Which processes need which competencies |
| Role-Competency Matrix (Org 1) | 224 | Org 1 | Calculated from above matrices |

---

## Critical: Why Organization 1 Matters

**Organization 1 serves as the TEMPLATE** for all new organizations!

When a new organization registers:
1. System COPIES `role_process_matrix` from Organization 1
2. System CALCULATES `role_competency_matrix` using the formula:
   ```
   role_competency = role_process (org-specific) × process_competency (global)
   ```

**If Organization 1 has empty matrices, ALL new organizations will be empty!**

---

## Verification

After setup, verify data is present:

```bash
python -c "
from app import create_app
from models import db
from sqlalchemy import text

app = create_app()
with app.app_context():
    checks = [
        ('iso_processes', 28),
        ('competency', 16),
        ('role_cluster', 14),
        ('role_process_matrix WHERE organization_id = 1', 392),
        ('process_competency_matrix', 448),
        ('role_competency_matrix WHERE organization_id = 1', 224),
    ]

    print('Data Verification:')
    print('-' * 60)
    for table, expected in checks:
        count = db.session.execute(text(f'SELECT COUNT(*) FROM {table};')).scalar()
        status = 'OK' if count >= expected else 'FAIL'
        print(f'[{status}] {table:50s} {count:4d} (expected >= {expected})')
"
```

**All checks should show [OK]!**

---

## Troubleshooting

### Error: "Cannot connect to database"
```bash
# Check PostgreSQL is running
pg_isready

# Check database exists
psql -U postgres -l | grep competency_assessment

# Create database manually if needed
psql -U postgres -c "CREATE DATABASE competency_assessment;"
psql -U postgres -c "CREATE USER ma0349 WITH PASSWORD 'MA0349_2025';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE competency_assessment TO ma0349;"
```

### Error: "Module not found"
```bash
# Activate virtual environment
cd src/backend
venv/Scripts/activate  # Windows
source venv/bin/activate  # Linux/Mac

# Install dependencies
pip install -r requirements.txt
```

### Error: "Script failed: populate_process_competency_matrix.py"
This script reads from Derik's reference SQL file. The path may need adjustment:

1. Check if file exists: `C:\Users\jomon\Documents\MyDocuments\Development\Thesis\sesurveyapp-main\postgres-init\filtered_init.sql`
2. If not, edit `populate_process_competency_matrix.py` line 35 to correct path
3. Or extract the data and embed it in the script

### All Checks Show 0 Entries
This means `initialize_all_data.py` was not run or failed. Run it manually:
```bash
cd src/backend
python initialize_all_data.py
```

---

## Starting the Server

After successful setup:

```bash
cd src/backend
set DATABASE_URL=postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment
python run.py --port 5000 --debug
```

Server will start on: `http://127.0.0.1:5000`

---

## Scripts Reference

| Script | Purpose | When to Run |
|--------|---------|-------------|
| `setup_database.py` | Master setup (creates DB + runs initialize_all_data.py) | Once, on new machine |
| `initialize_all_data.py` | Populates ALL required data | Once, or after database reset |
| `populate_iso_processes.py` | Populates ISO processes only | Rarely (usually run by initialize_all_data.py) |
| `populate_competencies.py` | Populates competencies only | Rarely |
| `populate_roles_and_matrices.py` | Populates roles + role-process for org 1 | Rarely |
| `populate_process_competency_matrix.py` | Populates process-competency (GLOBAL) | Rarely |
| `run.py` | Starts Flask server | Every time you want to run the app |

---

## Development Workflow

### First Time Setup
```bash
python setup_database.py
# Answer "yes" when prompted for data initialization
```

### Daily Development
```bash
cd src/backend
set DATABASE_URL=postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment
python run.py --port 5000 --debug
```

### After Database Reset
```bash
python initialize_all_data.py
```

---

## See Also

- `NEW_MACHINE_SETUP_GUIDE.md` - Comprehensive setup guide with risk analysis
- `DATABASE_INITIALIZATION_GUIDE.md` - Matrix architecture explanation
- `MATRIX_ENDPOINTS_IMPLEMENTATION_SUMMARY.md` - Admin matrix endpoints documentation

---

**Last Updated**: 2025-10-21
