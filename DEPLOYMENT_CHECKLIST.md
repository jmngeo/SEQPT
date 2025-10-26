# SE-QPT New Machine Deployment Checklist
**Version:** 1.0
**Last Updated:** 2025-10-26
**Purpose:** Complete guide for deploying SE-QPT on a new machine

---

## Prerequisites

### System Requirements
- [ ] **Operating System:** Windows 10/11 (or compatible)
- [ ] **Python:** 3.10 or higher
- [ ] **Node.js:** 16.x or higher
- [ ] **PostgreSQL:** 12.x or higher
- [ ] **Git:** Latest version
- [ ] **Memory:** Minimum 8GB RAM recommended
- [ ] **Storage:** At least 5GB free space

### Accounts & Access
- [ ] GitHub access to repository
- [ ] OpenAI API key (for Phase 2 & 3)
- [ ] PostgreSQL credentials (can be created during setup)

---

## Part 1: System Setup

### 1.1 Install Required Software

#### PostgreSQL Database
```bash
# Download and install PostgreSQL from:
# https://www.postgresql.org/download/windows/

# Verify installation
psql --version
```

#### Python & Node.js
```bash
# Verify Python
python --version  # Should be 3.10+

# Verify Node.js
node --version    # Should be 16.x+
npm --version
```

#### Git Bash (for Windows)
```bash
# Download from: https://git-scm.com/downloads
# Verify
git --version
```

---

## Part 2: Clone Repository

### 2.1 Clone the Project
```bash
cd /c/Users/<your-username>/Documents/
git clone <repository-url> SE-QPT-Master-Thesis
cd SE-QPT-Master-Thesis
```

### 2.2 Verify Repository Structure
```bash
# You should see:
tree -L 1
# ├── data/
# ├── src/
# ├── docs/
# ├── venv/          (will be created)
# ├── README.md
# └── .env           (will be created)
```

---

## Part 3: Database Setup

### 3.1 Create PostgreSQL Database

```bash
# Option 1: Using postgres superuser
psql -U postgres

# In psql:
CREATE DATABASE seqpt_database;
CREATE USER seqpt_admin WITH PASSWORD 'SeQpt_2025';
GRANT ALL PRIVILEGES ON DATABASE seqpt_database TO seqpt_admin;
\q
```

### 3.2 Verify Database Connection
```bash
psql -U seqpt_admin -d seqpt_database -h localhost
# Should connect successfully
\q
```

---

## Part 4: Backend Setup

### 4.1 Create Python Virtual Environment
```bash
cd /c/Users/<your-username>/Documents/SE-QPT-Master-Thesis

# Create venv
python -m venv venv

# Activate venv (Git Bash on Windows)
source venv/Scripts/activate

# Verify activation (should see (venv) prefix)
which python
```

### 4.2 Install Python Dependencies
```bash
# Ensure venv is activated
cd src/backend
pip install -r requirements.txt

# Verify critical packages
pip list | grep -E "Flask|psycopg2|openai|langchain|chromadb"
```

### 4.3 Create Environment File

Create `.env` file in project root:

```bash
cd /c/Users/<your-username>/Documents/SE-QPT-Master-Thesis
```

**File: `.env`**
```bash
# Database Configuration
DATABASE_URL=postgresql://seqpt_admin:SeQpt_2025@localhost:5432/seqpt_database

# Flask Configuration
FLASK_APP=run.py
FLASK_DEBUG=1
SECRET_KEY=your-secret-key-here-change-this

# OpenAI API (Required for Phase 2 & 3)
OPENAI_API_KEY=sk-your-openai-api-key-here

# Optional: Alternative database credentials
POSTGRES_USER=postgres
POSTGRES_PASSWORD=root
```

### 4.4 Verify Environment File
```bash
# Check .env exists
if [ -f .env ]; then echo "[OK] .env file exists"; else echo "[ERROR] .env file missing"; fi

# Test loading
python -c "from dotenv import load_dotenv; import os; load_dotenv(); print('[OK] DATABASE_URL:', os.getenv('DATABASE_URL')[:30] + '...')"
```

---

## Part 5: Data Directory Setup

### 5.1 Verify Critical Data Files

**All these files must exist:**

```bash
cd data

# Runtime files (CRITICAL)
ls -lh processed/archetype_competency_matrix.json
ls -lh processed/se_foundation_data.json
ls -lh processed/standard_learning_objectives.json
ls -lh source/templates/learning_objectives_guidelines.json

# Vector database
ls -lh rag_vectordb/chroma.sqlite3

# Source data
ls -lh source/excel/Qualifizierungsmodule_Qualifizierungspläne_v4_enUS.xlsx
```

**If any file is missing:**
1. Check the `data/archive/` directory
2. Restore from backup
3. Contact project maintainer

### 5.2 Data Files Checklist
- [ ] `processed/archetype_competency_matrix.json` exists
- [ ] `processed/se_foundation_data.json` exists
- [ ] `processed/standard_learning_objectives.json` exists
- [ ] `source/templates/learning_objectives_guidelines.json` exists
- [ ] `rag_vectordb/chroma.sqlite3` exists
- [ ] `source/excel/Qualifizierungsmodule_Qualifizierungspläne_v4_enUS.xlsx` exists

---

## Part 6: Database Initialization

### 6.1 Initialize Database Schema and Data

```bash
cd src/backend/setup/populate

# Run the master initialization script
python initialize_all_data.py
```

**Expected Output:**
```
[STEP 1/7] Populate ISO/IEC 15288 Processes (28 entries)
[OK] populate_iso_processes.py completed successfully

[STEP 2/7] Populate SE Competencies (16 entries)
[OK] populate_competencies.py completed successfully

[STEP 3/7] Populate Roles + Role-Process Matrix (14 + 392 entries)
[OK] populate_roles_and_matrices.py completed successfully

[STEP 4/7] Populate Process-Competency Matrix (448 entries)
[OK] populate_process_competency_matrix.py completed successfully

[STEP 5/7] Create PostgreSQL Stored Procedures
[OK] Stored procedures created

[STEP 6/7] Calculate Role-Competency Matrix for Organization 1
[OK] Calculated 224 role-competency entries

[SUCCESS] All data initialized successfully!
```

### 6.2 Verify Database Population

```bash
# Connect to database
psql -U seqpt_admin -d seqpt_database -h localhost

# Run verification queries
SELECT COUNT(*) as processes FROM iso_processes;
-- Expected: 28

SELECT COUNT(*) as competencies FROM competency;
-- Expected: 16

SELECT COUNT(*) as roles FROM role_cluster;
-- Expected: 14

SELECT COUNT(*) as role_process_matrix FROM role_process_matrix WHERE organization_id = 1;
-- Expected: 392

SELECT COUNT(*) as process_competency_matrix FROM process_competency_matrix;
-- Expected: 448

SELECT COUNT(*) as role_competency_matrix FROM role_competency_matrix WHERE organization_id = 1;
-- Expected: 224

\q
```

### 6.3 Database Checklist
- [ ] iso_processes table populated (28 entries)
- [ ] competency table populated (16 entries)
- [ ] role_cluster table populated (14 entries)
- [ ] role_process_matrix populated (392 entries for org 1)
- [ ] process_competency_matrix populated (448 entries)
- [ ] role_competency_matrix populated (224 entries for org 1)
- [ ] Stored procedures created successfully

---

## Part 7: Frontend Setup

### 7.1 Install Frontend Dependencies

```bash
cd src/frontend

# Install npm packages
npm install

# Verify critical packages
npm list | grep -E "vue|vuetify|vite|axios"
```

### 7.2 Configure Frontend

**File: `src/frontend/.env`** (if needed)
```bash
VITE_API_BASE_URL=http://127.0.0.1:5000
```

### 7.3 Build Frontend (Optional)
```bash
# For production
npm run build

# For development, skip this step
```

---

## Part 8: Start the Application

### 8.1 Start Backend Server

**Terminal 1:**
```bash
cd /c/Users/<your-username>/Documents/SE-QPT-Master-Thesis

# Activate venv
source venv/Scripts/activate

# Start Flask
cd src/backend
python run.py
```

**Expected Output:**
```
[DATABASE] Using: postgresql://seqpt_admin:***@localhost:5432/seqpt_database
Unified routes registered successfully (main + MVP in single blueprint)
[SUCCESS] Derik's competency assessor integration enabled (RAG-LLM pipeline loaded)
 * Serving Flask app 'app'
 * Debug mode: off
 * Running on http://127.0.0.1:5000
Press CTRL+C to quit
```

### 8.2 Start Frontend Development Server

**Terminal 2:**
```bash
cd /c/Users/<your-username>/Documents/SE-QPT-Master-Thesis/src/frontend

npm run dev
```

**Expected Output:**
```
VITE v5.4.20  ready in 5680 ms

➜  Local:   http://localhost:3000/
➜  Network: http://192.168.x.x:3000/
```

---

## Part 9: Verify Application

### 9.1 Access the Application

Open browser and navigate to:
- **Frontend:** http://localhost:3000
- **Backend API:** http://127.0.0.1:5000/api/health

### 9.2 Test Basic Functionality

#### Test 1: Health Check
```bash
curl http://127.0.0.1:5000/api/health
```

**Expected:** `{"status": "healthy"}`

#### Test 2: Get Competencies
```bash
curl http://127.0.0.1:5000/api/competencies
```

**Expected:** JSON array with 16 competencies

#### Test 3: Get Roles
```bash
curl http://127.0.0.1:5000/api/roles
```

**Expected:** JSON array with 14 roles

### 9.3 Frontend Verification Checklist
- [ ] Home page loads successfully
- [ ] Dashboard accessible
- [ ] Phase 1 components load
- [ ] Phase 2 components load
- [ ] No console errors

---

## Part 10: Optional Configuration

### 10.1 Setup Git Configuration (if needed)

```bash
# Configure user
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Verify
git config --list
```

### 10.2 Create Test User (Optional)

```bash
# Via Python shell
cd src/backend
python

>>> from app import create_app
>>> from models import db, User
>>> app = create_app()
>>> with app.app_context():
...     user = User(username='test_user', email='test@example.com')
...     user.set_password('test123')
...     db.session.add(user)
...     db.session.commit()
...     print(f"User created: {user.username}")
>>> exit()
```

---

## Troubleshooting

### Database Connection Issues

**Problem:** `psycopg2.OperationalError: could not connect to server`

**Solutions:**
1. Verify PostgreSQL is running:
   ```bash
   tasklist | findstr postgres
   ```

2. Check DATABASE_URL in `.env`:
   ```bash
   cat .env | grep DATABASE_URL
   ```

3. Test connection manually:
   ```bash
   psql -U seqpt_admin -d seqpt_database -h localhost
   ```

### Missing Python Packages

**Problem:** `ModuleNotFoundError: No module named 'flask'`

**Solution:**
```bash
# Activate venv first!
source venv/Scripts/activate

# Reinstall requirements
cd src/backend
pip install -r requirements.txt
```

### Port Already in Use

**Problem:** `Address already in use: Port 5000`

**Solution:**
```bash
# Find process using port
tasklist | findstr python

# Kill process
taskkill /PID <process-id> /F

# Or use different port in run.py
```

### Frontend Won't Start

**Problem:** `npm run dev` fails

**Solutions:**
1. Clear npm cache:
   ```bash
   npm cache clean --force
   ```

2. Delete node_modules and reinstall:
   ```bash
   rm -rf node_modules
   npm install
   ```

### RAG Vector Database Issues

**Problem:** `ChromaDB connection error`

**Solution:**
1. Verify vector DB exists:
   ```bash
   ls -lh data/rag_vectordb/chroma.sqlite3
   ```

2. If missing, restore from backup or contact maintainer

---

## Post-Deployment Checklist

### Essential Checks
- [ ] Backend server starts without errors
- [ ] Frontend dev server starts successfully
- [ ] Database connection working
- [ ] All critical data files present
- [ ] OpenAI API key configured (if using Phase 2/3)
- [ ] Application accessible at http://localhost:3000
- [ ] No errors in browser console
- [ ] Basic API endpoints responding

### Security Checks
- [ ] `.env` file is in `.gitignore`
- [ ] Database credentials are secure
- [ ] OpenAI API key is not committed to git
- [ ] SECRET_KEY changed from default

### Performance Checks
- [ ] Page load time < 3 seconds
- [ ] API response time < 1 second
- [ ] No memory leaks in backend
- [ ] Frontend builds successfully

---

## Quick Start Commands

**For subsequent startups after initial deployment:**

```bash
# Terminal 1 - Backend
cd /c/Users/<your-username>/Documents/SE-QPT-Master-Thesis
source venv/Scripts/activate
cd src/backend
python run.py

# Terminal 2 - Frontend
cd /c/Users/<your-username>/Documents/SE-QPT-Master-Thesis/src/frontend
npm run dev
```

**Application URLs:**
- Frontend: http://localhost:3000
- Backend: http://127.0.0.1:5000

---

## Support & Documentation

### Key Documentation Files
- `README.md` - Project overview
- `DATA_DIRECTORY_ANALYSIS.md` - Data files documentation
- `SESSION_HANDOVER.md` - Development history
- `DATABASE_INITIALIZATION_GUIDE.md` - Database setup details

### Getting Help
1. Check documentation in `/docs` directory
2. Review SESSION_HANDOVER.md for recent issues
3. Check GitHub issues
4. Contact project maintainer

---

**Deployment Checklist Complete!**
**Last Updated:** 2025-10-26
**Version:** 1.0

If all checkboxes are complete, your SE-QPT installation is ready for use!
