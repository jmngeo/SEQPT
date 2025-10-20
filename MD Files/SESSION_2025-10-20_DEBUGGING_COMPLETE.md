# Debugging Session - 2025-10-20

**Date:** October 20, 2025
**Duration:** ~4 hours
**Status:** Root causes identified, cleanup plan created
**Next Steps:** Execute codebase refactoring plan in next session

---

## Executive Summary

This session uncovered a **cascade of architectural confusion** caused by:
1. **Dual Backend Architecture** - Two separate backends causing confusion
2. **Port Configuration Drift** - Vite proxy pointing to wrong port
3. **API Endpoint Mismatches** - Frontend calling wrong endpoints
4. **Model Import Conflicts** - SQLAlchemy relationship errors from fragmented models

**Final Status:** All root causes identified and documented. Refactoring plan created for next session.

---

## Problem Timeline

### Initial Symptom
```
GET /api/organization/dashboard 404 (NOT FOUND)
GET /api/phase1/maturity/29/latest 404 (NOT FOUND)
```

### Investigation Journey

#### Discovery #1: Wrong Backend Running
- **Found:** Two backend directories exist
  - `src/backend/` - Main SE-QPT backend (CORRECT)
  - `src/competency_assessor/` - Legacy Derik Phase 2 backend (WRONG)
- **Issue:** We were running the wrong backend
- **Impact:** Missing ALL Phase 1 routes

#### Discovery #2: Port Configuration Incorrect
- **Found:** Commit `261d5239` incorrectly changed port from 5000 to 5003
- **Issue:** Vite proxy pointing to port 5003, but correct backend runs on 5000
- **Impact:** Even when running correct backend, requests couldn't reach it

#### Discovery #3: API Endpoint Mismatches
- **Found:** Frontend calling `/login`, backend route is `/mvp/auth/login`
- **Issue:** MVP routes blueprint not being registered due to import error
- **Impact:** 404 errors on authentication

#### Discovery #4: Model Import Conflicts (CURRENT BLOCKER)
- **Found:** SQLAlchemy error - `'SECompetency' failed to locate a name`
- **Issue:** Fragmented model architecture across 3 files
- **Impact:** 500 Internal Server Error on login

---

## Root Cause: Fragmented Architecture

### The Model Mess

The codebase has **THREE conflicting model definitions**:

```
src/backend/
├── models.py           # Original SE-QPT models (references SECompetency)
├── unified_models.py   # Derik integration models
└── mvp_models.py       # MVP simplified models (imports from both above)
```

**The Problem:**
- `models.py` defines `CompetencyAssessmentResult` with relationship to `'SECompetency'`
- `'SECompetency'` class doesn't exist (should be just `Competency`)
- `unified_models.py` has `Competency` but it's not called `SECompetency`
- `mvp_models.py` tries to import from both, causing conflicts
- SQLAlchemy can't resolve the relationships → 500 errors

### The Routes Mess

The codebase has **FOUR route files**:

```
src/backend/app/
├── routes.py           # Main routes (basic CRUD)
├── mvp_routes.py       # MVP API routes (authentication, Phase 1)
├── seqpt_routes.py     # SE-QPT specific routes (RAG, objectives)
└── derik_integration.py # Derik's Phase 2 routes
```

**The Problem:**
- Overlapping responsibilities
- No clear separation of concerns
- Authentication split across multiple files
- Hard to understand which route belongs where

### The Backend Mess

```
src/
├── backend/            # Main backend (correct one)
└── competency_assessor/ # Legacy backend (confusing, partially functional)
```

**The Problem:**
- Two backends with similar names
- Not clear which one to run
- `competency_assessor` has Phase 2 code that's needed
- Can't just delete it without migration

---

## Errors Encountered (In Order)

### 1. Phase 1 Routes 404
```
GET /api/organization/dashboard 404 (NOT FOUND)
GET /api/phase1/maturity/29/latest 404 (NOT FOUND)
```
**Cause:** Running wrong backend (`src/competency_assessor/`)
**Fix:** Started `src/backend/` instead

### 2. Login Route 404
```
POST /login 404 (NOT FOUND)
```
**Cause:** Wrong proxy configuration (5003 vs 5000)
**Fix:** Updated vite.config.js to proxy to port 5000

### 3. MVP Routes Not Registered
```
Warning: MVP API routes not available: cannot import name 'db' from 'app'
```
**Cause:** `db` not exported from `app/__init__.py`
**Fix:** Added module-level db import

### 4. Wrong Login Endpoint
```
POST /login 404 (NOT FOUND)
```
**Cause:** Frontend calling `/login`, backend route at `/mvp/auth/login`
**Fix:** Updated auth.js to use correct endpoints

### 5. SQLAlchemy Relationship Error (CURRENT)
```
ERROR: expression 'SECompetency' failed to locate a name ('SECompetency')
POST /mvp/auth/login 500 (INTERNAL SERVER ERROR)
```
**Cause:** Fragmented model architecture, undefined class reference
**Fix Required:** Unify model files (see refactoring plan below)

---

## Fixes Applied This Session

### 1. Backend Selection ✅
**File:** Manual startup process
**Change:** Run `src/backend/` on port 5000 instead of `src/competency_assessor/` on 5003

### 2. Vite Proxy Configuration ✅
**File:** `src/frontend/vite.config.js`
**Changes:**
```javascript
proxy: {
  '/api': {
    target: 'http://localhost:5000',  // Was: 5003
  },
  '/mvp': {  // ADDED
    target: 'http://localhost:5000',
  },
  '/login': {  // ADDED
    target: 'http://localhost:5000',
  }
}
```

### 3. DB Module Export ✅
**File:** `src/backend/app/__init__.py`
**Changes:**
```python
# Added at module level (line 23)
from models import db

# Removed duplicate import inside create_app()
```

### 4. Authentication Endpoints ✅
**File:** `src/frontend/src/api/auth.js`
**Changes:**
```javascript
// Was: '/login'
// Now: '/mvp/auth/login'

login: (credentials) => {
  return axios.post('/mvp/auth/login', { ... })
},
registerAdmin: (userData) => {
  return axios.post('/mvp/auth/register-admin', { ... })
},
registerEmployee: (userData) => {
  return axios.post('/mvp/auth/register-employee', { ... })
}
```

### 5. Startup Scripts Created ✅
**Files:**
- `start_backend.bat` - Starts correct backend
- `start_frontend.bat` - Starts frontend
- `STARTUP_README.md` - Comprehensive startup guide

---

## Files Modified This Session

### Backend
1. `src/backend/app/__init__.py` - Added db module export
2. `src/competency_assessor/run.py` - Created (was empty)
3. `src/competency_assessor/app/__init__.py` - Added mvp_routes registration

### Frontend
1. `src/frontend/vite.config.js` - Fixed proxy ports and added routes
2. `src/frontend/src/api/auth.js` - Updated authentication endpoints

### Documentation
1. `STARTUP_README.md` - New comprehensive startup guide
2. `start_backend.bat` - New startup script
3. `start_frontend.bat` - New startup script

---

## Current System State

### Running Services
- ✅ Backend: `src/backend/` on port 5000
- ✅ Frontend: Vite dev server on port 3002
- ✅ Database: PostgreSQL on port 5432

### What Works
- ✅ Backend starts successfully
- ✅ Frontend starts successfully
- ✅ Proxy configuration correct
- ✅ MVP routes registered
- ✅ Authentication endpoints correctly mapped

### What Doesn't Work
- ❌ **Login returns 500 error** - SQLAlchemy relationship error
- ❌ Model architecture fragmented and conflicting
- ❌ Can't access any protected routes

---

## Why Everything Broke After Phase 2 Restoration

### The Backup Restoration (Commit: 7d25526b)
1. **Restored:** Frontend Phase 2 components from backup
2. **Did NOT restore:** Backend configuration and startup scripts
3. **Introduced:** Port configuration pointing to wrong backend

### The "Fix" That Made It Worse (Commit: 261d5239)
1. **Changed:** All ports from 5000 to 5003
2. **Reasoning:** Assumed 5000 was wrong
3. **Actual Effect:** Broke connection to correct backend
4. **Quote from commit:** "Backend: Running on port 5003 (Flask)"
   - This was **WRONG** - correct backend runs on 5000

### The Cascade
```
Backup Restoration
  ↓
Port Confusion (5000 vs 5003)
  ↓
Running Wrong Backend
  ↓
Phase 1 404 Errors
  ↓
Fixed Port, But...
  ↓
Wrong Login Endpoints
  ↓
Fixed Endpoints, But...
  ↓
Model Import Conflicts (Current State)
```

---

## Key Lessons Learned

### 1. Documentation is Critical
- No README explaining which backend to run
- No clear indication of port requirements
- Startup process not documented

### 2. Multiple Backends = Confusion
- Having `backend/` and `competency_assessor/` caused hours of debugging
- Names are too similar
- Should have ONE backend or clear migration path

### 3. Try/Except Hiding Real Errors
- MVP routes registration wrapped in try/except
- Showed "success" even when imports failed
- Delayed discovery of real issue

### 4. Model Architecture Matters
- Three model files with circular dependencies
- SQLAlchemy relationship strings not validated until runtime
- Model unification critical for stability

---

## Next Session: Refactoring Plan

See `CODEBASE_CLEANUP_PLAN.md` for detailed steps.

**Priority:**
1. Fix SQLAlchemy relationship error (immediate)
2. Unify model files (critical)
3. Unify route files (important)
4. Migrate/remove legacy backend (cleanup)

---

## Appendices

### A. Backend Error Log (Latest)
```
ERROR:app:Login error: When initializing mapper Mapper[CompetencyAssessmentResult(competency_assessment_results)], expression 'SECompetency' failed to locate a name ('SECompetency'). If this is a class name, consider adding this relationship() to the <class 'models.CompetencyAssessmentResult'> class after both dependent classes have been defined.
```

### B. Correct Backend Startup Output
```
[SUCCESS] Derik's competency assessor integration enabled (RAG-LLM pipeline loaded)
Derik's competency assessor integration enabled
RAG-LLM components initialized successfully
SE-QPT RAG routes registered successfully
MVP API routes registered successfully
 * Serving Flask app 'app'
 * Debug mode: on
 * Running on http://127.0.0.1:5000
```

### C. Incorrect Backend Indicators
If you see NO success messages or running on different port, you're running wrong backend!

---

**End of Session Documentation**
