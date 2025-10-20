# SE-QPT Application Startup Guide

**CRITICAL:** This project has TWO backend directories. You MUST use the correct one!

---

## Quick Start

### Option 1: Use Startup Scripts (Recommended)

1. **Start Backend:**
   ```
   Double-click: start_backend.bat
   ```
   - Starts `src/backend/` on port **5000**
   - You should see: `[SUCCESS] Derik's competency assessor integration enabled`

2. **Start Frontend:**
   ```
   Double-click: start_frontend.bat
   ```
   - Starts `src/frontend/` on port **3000**
   - Proxies requests to backend on port 5000

3. **Access Application:**
   ```
   http://localhost:3000
   ```

---

## Option 2: Manual Startup

### Backend (CORRECT)

```bash
cd src/backend
set DATABASE_URL=postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment
..\..\venv\Scripts\activate
python run.py --port 5000 --debug
```

**You should see:**
```
[SUCCESS] Derik's competency assessor integration enabled
RAG-LLM components initialized successfully
SE-QPT RAG routes registered successfully
MVP API routes registered successfully
Running on http://127.0.0.1:5000
```

### Frontend

```bash
cd src/frontend
npm run dev
```

**You should see:**
```
VITE v5.4.20 ready in XXXX ms
Local: http://localhost:3000/
```

---

## CRITICAL: Which Backend to Use?

### ✅ CORRECT Backend: `src/backend/`

- **Port:** 5000
- **Purpose:** Complete SE-QPT application
- **Features:**
  - Phase 1 routes (maturity, roles, strategies)
  - Phase 2 routes (competency assessment)
  - RAG-LLM integration
  - Organization dashboard
  - Authentication

### ❌ WRONG Backend: `src/competency_assessor/`

- **Purpose:** Legacy Phase 2-only backend (Derik's original)
- **Problem:** Missing ALL Phase 1 routes
- **Do NOT use this backend!**

---

## How to Verify You're Running the Correct Backend

### Check Console Output

**CORRECT backend shows:**
```
[SUCCESS] Derik's competency assessor integration enabled
RAG-LLM components initialized successfully
```

**WRONG backend shows:**
```
(No special initialization messages)
```

### Test an Endpoint

```bash
# Test Phase 1 dashboard route
curl http://localhost:5000/api/organization/dashboard?code=BXUPF9
```

**CORRECT backend:**
- Returns 401 (Unauthorized) or data ✅

**WRONG backend:**
- Returns 404 (Not Found) ❌

---

## Troubleshooting

### Problem: 404 Errors for Phase 1 Routes

**Symptom:**
```
GET /api/organization/dashboard 404
GET /api/phase1/maturity/29/latest 404
```

**Cause:** You're running the WRONG backend (`src/competency_assessor/`)

**Solution:**
1. Stop the running backend (Ctrl+C)
2. Start the CORRECT backend using `start_backend.bat`
3. Verify console shows `[SUCCESS] Derik's competency assessor integration enabled`

### Problem: Connection Refused

**Symptom:**
```
GET http://localhost:5000/api/... ERR_CONNECTION_REFUSED
```

**Cause:** Backend not running

**Solution:** Start backend using `start_backend.bat`

### Problem: Port 5000 Already in Use

**Symptom:**
```
OSError: [WinError 10048] Only one usage of each socket address
```

**Solution:**
```bash
# Find process using port 5000
netstat -ano | findstr :5000

# Kill the process (replace PID with actual process ID)
taskkill /PID <PID> /F
```

### Problem: Frontend Shows 401 Errors

**Symptom:**
```
GET /api/organization/dashboard 401 (Unauthorized)
```

**Cause:** Not logged in (this is NORMAL after starting servers)

**Solution:** Log in through the application

---

## Database Configuration

**Connection String:**
```
postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment
```

**Alternative Credentials (if above doesn't work):**
- `postgres:postgres`
- `postgres:root`

---

## Port Configuration

| Service | Port | Purpose |
|---------|------|---------|
| Backend | 5000 | Flask API server |
| Frontend | 3000 | Vite dev server (or 3001 if 3000 is busy) |
| PostgreSQL | 5432 | Database |

---

## Next Steps After Startup

1. Open browser: `http://localhost:3000`
2. Login with your credentials
3. Navigate to Phase 1 for maturity assessment
4. Test Phase 2 competency assessment

---

## Important Notes

- ⚠️ Flask hot-reload doesn't work reliably - restart backend manually after code changes
- ⚠️ No emojis in code (Windows console encoding issues)
- ⚠️ Always check SESSION_HANDOVER.md for latest session notes
- ✅ Both servers must be running for the application to work

---

**Last Updated:** 2025-10-20
**Issue:** Dual backend confusion discovered and documented
