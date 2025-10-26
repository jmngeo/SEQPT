# Database Rename Guide

## Is It App-Breaking? **NO** ✓

Renaming your PostgreSQL database and username is **safe and non-destructive** if you follow the proper steps. The main application reads credentials from `.env`, so updating that file is the primary change needed.

## Current Setup
- **Database**: `competency_assessment`
- **Username**: `ma0349`
- **Password**: `MA0349_2025`

## Example New Setup (Edit `rename_database.py` to customize)
- **Database**: `seqpt_database`
- **Username**: `seqpt_admin`
- **Password**: `SeQpt_2025`

## What Gets Updated

### Automatically Updated by Script:
1. ✓ PostgreSQL database name
2. ✓ PostgreSQL user creation
3. ✓ Ownership and permissions
4. ✓ `.env` file
5. ✓ `CLAUDE.md` file (user documentation)
6. ✓ Backups created before changes

### Manually Update After (Optional):
These are utility/test scripts with hardcoded credentials. They won't affect your main app:
- `backup_database.py` - Update DB_USER and DB_PASSWORD constants
- Various test/populate scripts in `src/backend/` - Update connection strings if you use them

## How to Rename

### Step 1: Edit the Script
Open `src/backend/rename_database.py` and modify these lines:

```python
# New credentials (modify these as needed)
NEW_DB_USER = "seqpt_admin"      # Your desired username
NEW_DB_PASSWORD = "SeQpt_2025"   # Your desired password
NEW_DB_NAME = "seqpt_database"   # Your desired database name
```

### Step 2: Run the Script

```bash
cd C:\Users\jomon\Documents\MyDocuments\Development\Thesis\SE-QPT-Master-Thesis\src\backend
..\..\venv\Scripts\python.exe rename_database.py
```

You'll need the **postgres superuser password** when prompted.

### Step 3: Restart Your Flask Server

After the rename:
1. Kill the current Flask server
2. Restart it - it will now use the new credentials from `.env`

### Step 4: Verify

```bash
# Test connection with new credentials
psql -U seqpt_admin -h localhost -p 5432 -d seqpt_database

# Or check from Python
../../venv/Scripts/python.exe -c "from app import create_app; app = create_app(); print('Connection successful!')"
```

## What the Script Does (In Order)

1. **Creates Backup** - Full SQL dump of current database
2. **Creates New User** - PostgreSQL user with specified password
3. **Renames Database** - Safely renames using ALTER DATABASE
4. **Transfers Ownership** - Grants all privileges to new user
5. **Updates .env** - Replaces DATABASE_URL with new credentials
6. **Updates CLAUDE.md** - Updates user documentation with new credentials

## Safety Features

- ✓ **Automatic backup** before any changes
- ✓ **Backs up .env** before modifying
- ✓ **Disconnects users** before renaming database
- ✓ **Confirmation prompt** before proceeding
- ✓ **No data loss** - all data is preserved

## Manual Method (If You Prefer)

If you want to do it manually without the script:

```sql
-- 1. Create new user (as postgres superuser)
CREATE USER seqpt_admin WITH PASSWORD 'SeQpt_2025' CREATEDB;

-- 2. Rename database (as postgres superuser)
-- First disconnect all users
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'competency_assessment'
AND pid <> pg_backend_pid();

-- Then rename
ALTER DATABASE competency_assessment RENAME TO seqpt_database;

-- 3. Transfer ownership
ALTER DATABASE seqpt_database OWNER TO seqpt_admin;
GRANT ALL PRIVILEGES ON DATABASE seqpt_database TO seqpt_admin;

-- 4. Connect to new database and grant schema permissions
\c seqpt_database
GRANT ALL PRIVILEGES ON SCHEMA public TO seqpt_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO seqpt_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO seqpt_admin;
```

Then manually update `.env`:
```bash
# Old
DATABASE_URL=postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment

# New
DATABASE_URL=postgresql://seqpt_admin:SeQpt_2025@localhost:5432/seqpt_database
```

## Utility Scripts to Update (Optional)

After renaming, these scripts will have old credentials but won't affect the main app:

```bash
# Find all files with hardcoded credentials
cd src/backend
grep -r "ma0349" *.py
grep -r "competency_assessment" *.py
```

Update the connection strings in:
- `backup_database.py` (lines 9-12)
- Test scripts (`test_*.py`)
- Populate scripts (`populate_*.py`)
- Analysis scripts (`analyze_*.py`)

Or just use the new credentials from `.env` in those scripts instead of hardcoding them.

## Rollback (If Needed)

If something goes wrong, restore from backup:

```bash
# 1. Rename database back
psql -U postgres -c "ALTER DATABASE seqpt_database RENAME TO competency_assessment;"

# 2. Restore from backup
psql -U ma0349 -h localhost -p 5432 competency_assessment < backups/pre_rename_backup_TIMESTAMP.sql

# 3. Restore .env from backup
# Look for .env.backup_TIMESTAMP in project root
```

## Bottom Line

**This is NOT app-breaking.** The Flask app is designed to read from `.env`, so changing credentials is a routine operation. The automated script handles all the complexity for you.

**Time Required**: 2-5 minutes (mostly entering postgres password)

**Risk Level**: Low (backup created automatically)

**Downtime**: ~1 minute (restart Flask server)
