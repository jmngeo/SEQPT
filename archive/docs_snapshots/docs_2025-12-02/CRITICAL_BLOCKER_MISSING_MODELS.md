# CRITICAL BLOCKER: Missing Python Models in models.py

**Status**: BLOCKING BACKEND STARTUP
**Severity**: CRITICAL
**Discovered**: 2025-11-06, 07:20 AM
**Impact**: Backend cannot start, learning objectives generation blocked

---

## Problem Summary

The backend fails to start with this error:
```
ImportError: cannot import name 'StrategyTemplate' from 'models'
```

**Root Cause**: Database migration created new tables (`strategy_template`, `strategy_template_competency`) but the corresponding Python ORM models were never added to `models.py`.

---

## What's Missing

### 1. StrategyTemplate Model (NEW - needs to be created)

**Database Table Structure** (already exists):
```sql
Table: strategy_template
- id: integer (primary key, auto-increment)
- strategy_name: varchar(255) NOT NULL
- strategy_description: text
- requires_pmt_context: boolean (default: false)
- is_active: boolean (default: true)
- created_at: timestamp (default: CURRENT_TIMESTAMP)
- updated_at: timestamp (default: CURRENT_TIMESTAMP)

Unique constraint: strategy_name
```

**Python Model** (MISSING - needs to be added to models.py):
```python
class StrategyTemplate(db.Model):
    """
    Global Strategy Templates (Archetypes)
    ======================================

    Defines the 7 canonical qualification strategies from the template JSON.
    These are global templates that organizations instantiate via learning_strategy.

    The 7 strategies:
    1. Common basic understanding
    2. SE for managers
    3. Orientation in pilot project
    4. Needs-based, project-oriented training
    5. Continuous support
    6. Train the trainer
    7. Certification

    Each strategy has associated competency target levels defined in
    strategy_template_competency table.

    Created: 2025-11-05 (Global Strategy Templates Migration)
    """
    __tablename__ = 'strategy_template'

    id = db.Column(db.Integer, primary_key=True)
    strategy_name = db.Column(db.String(255), nullable=False, unique=True)
    strategy_description = db.Column(db.Text)
    requires_pmt_context = db.Column(db.Boolean, default=False)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    template_competencies = db.relationship(
        'StrategyTemplateCompetency',
        back_populates='strategy_template',
        cascade="all, delete-orphan",
        lazy=True
    )
    learning_strategies = db.relationship(
        'LearningStrategy',
        back_populates='strategy_template',
        lazy=True
    )

    def to_dict(self):
        """Convert to dictionary for API responses"""
        return {
            'id': self.id,
            'strategy_name': self.strategy_name,
            'description': self.strategy_description,
            'requires_pmt_context': self.requires_pmt_context,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
```

**Where to Add**: Insert BEFORE `LearningStrategy` class (around line 465 in models.py)

---

### 2. StrategyTemplateCompetency Model (NEW - needs to be created)

**Database Table Structure** (already exists):
```sql
Table: strategy_template_competency
- id: integer (primary key, auto-increment)
- strategy_template_id: integer NOT NULL (FK to strategy_template.id)
- competency_id: integer NOT NULL (FK to competency.id)
- target_level: integer NOT NULL (CHECK: 1-6)
- created_at: timestamp (default: CURRENT_TIMESTAMP)
- updated_at: timestamp (default: CURRENT_TIMESTAMP)

Unique constraint: (strategy_template_id, competency_id)
Indexes:
- idx_strategy_template_competency_template
- idx_strategy_template_competency_competency
```

**Python Model** (MISSING - needs to be added to models.py):
```python
class StrategyTemplateCompetency(db.Model):
    """
    Strategy Template Competency Target Levels
    ==========================================

    Defines the target competency levels for each global strategy template.

    This is the source of truth that maps:
    - 7 strategies × 16 competencies = 112 total mappings

    Example:
    - Strategy: "SE for managers"
    - Competency: "Systems Modelling and Analysis" (ID=6)
    - Target Level: 1 (basic awareness)

    Validated: 2025-11-06 - 100% data integrity confirmed
    All 112 mappings match template JSON exactly.

    Created: 2025-11-05 (Global Strategy Templates Migration)
    """
    __tablename__ = 'strategy_template_competency'

    id = db.Column(db.Integer, primary_key=True)
    strategy_template_id = db.Column(
        db.Integer,
        db.ForeignKey('strategy_template.id', ondelete='CASCADE'),
        nullable=False
    )
    competency_id = db.Column(
        db.Integer,
        db.ForeignKey('competency.id', ondelete='CASCADE'),
        nullable=False
    )
    target_level = db.Column(db.Integer, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    strategy_template = db.relationship(
        'StrategyTemplate',
        back_populates='template_competencies'
    )
    competency = db.relationship('Competency')

    # Table constraints
    __table_args__ = (
        db.UniqueConstraint(
            'strategy_template_id',
            'competency_id',
            name='strategy_template_competency_strategy_template_id_competenc_key'
        ),
        db.CheckConstraint(
            'target_level >= 1 AND target_level <= 6',
            name='strategy_template_competency_target_level_check'
        ),
        db.Index('idx_strategy_template_competency_template', 'strategy_template_id'),
        db.Index('idx_strategy_template_competency_competency', 'competency_id'),
    )

    def to_dict(self):
        """Convert to dictionary for API responses"""
        return {
            'id': self.id,
            'strategy_template_id': self.strategy_template_id,
            'competency_id': self.competency_id,
            'target_level': self.target_level,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
```

**Where to Add**: Insert AFTER `StrategyTemplate` class, BEFORE `LearningStrategy` class

---

### 3. LearningStrategy Model (UPDATE EXISTING)

**Database Table** (already has the field):
```sql
Table: learning_strategy
...existing fields...
- strategy_template_id: integer (FK to strategy_template.id)
```

**Current Python Model** (MISSING field):
```python
class LearningStrategy(db.Model):
    # ... existing fields ...
    # MISSING: strategy_template_id field
```

**Required Changes**:
Add this field to the existing `LearningStrategy` class (around line 515):
```python
strategy_template_id = db.Column(
    db.Integer,
    db.ForeignKey('strategy_template.id'),
    nullable=True  # Can be null for custom strategies
)
```

Add this relationship (around line 525):
```python
strategy_template = db.relationship(
    'StrategyTemplate',
    back_populates='learning_strategies'
)
```

---

## Error Location

**File**: `src/backend/setup/setup_phase2_task3_for_org.py`
**Line**: 15
**Code**:
```python
from models import StrategyTemplate, LearningStrategy, Organization
```

This import fails because `StrategyTemplate` doesn't exist in models.py.

---

## Database Verification

All tables and data exist correctly in the database:

```sql
-- Verify strategy_template table
SELECT COUNT(*) FROM strategy_template;
-- Result: 7 strategies

-- Verify strategy_template_competency table
SELECT COUNT(*) FROM strategy_template_competency;
-- Result: 112 mappings (7 × 16 = 112) [OK]

-- Verify data integrity
-- All 112 mappings validated as 100% correct (2025-11-06)
```

---

## Impact Analysis

**Blocked Features**:
- ✗ Backend startup (CRITICAL)
- ✗ Learning objectives generation
- ✗ Phase 2 setup for organizations
- ✗ All API endpoints

**Working Features**:
- ✓ Database (all tables and data intact)
- ✓ Frontend (running on localhost:3000)
- ✓ PostgreSQL (running on localhost:5432)

---

## Fix Steps for Next Session

### Step 1: Add StrategyTemplate Model
1. Open `src/backend/models.py`
2. Find line ~465 (before `class LearningStrategy`)
3. Insert the `StrategyTemplate` model (see code above)

### Step 2: Add StrategyTemplateCompetency Model
1. Immediately after `StrategyTemplate` class
2. Before `LearningStrategy` class
3. Insert the `StrategyTemplateCompetency` model (see code above)

### Step 3: Update LearningStrategy Model
1. Find the `LearningStrategy` class (line ~466)
2. Add `strategy_template_id` field after line 520
3. Add `strategy_template` relationship after line 525

### Step 4: Test Backend Startup
```bash
cd /c/Users/jomon/Documents/MyDocuments/Development/Thesis/SE-QPT-Master-Thesis/src/backend
PYTHONPATH=src/backend ../../venv/Scripts/python.exe run.py
```

### Step 5: Verify Import
```bash
python -c "from models import StrategyTemplate, StrategyTemplateCompetency, LearningStrategy; print('OK')"
```

---

## Files Modified (Next Session)

**Will Modify**:
- `src/backend/models.py` (add 2 models, update 1 model)

**No Database Changes Required**:
- All tables already exist
- All data already validated (100% integrity)
- No migrations needed

---

## Testing Checklist (After Fix)

- [ ] Backend starts without errors
- [ ] Import `StrategyTemplate` works
- [ ] Import `StrategyTemplateCompetency` works
- [ ] Import `LearningStrategy` works
- [ ] Learning objectives generation works for org 28
- [ ] Learning objectives generation works for org 29
- [ ] Frontend displays correct data

---

## Data Integrity Confirmed

**Validation Results** (2025-11-06):
- Expected mappings: 112
- Correct mappings: 112 [OK]
- Mismatches: 0
- Data Integrity: **100.0%**

**Report**: `VALIDATION_REPORT_ALL_112_MAPPINGS.md`

---

## Related Documentation

- `COMPETENCY_STRATEGY_STANDARDIZATION_REPORT.md` - Full analysis
- `VALIDATION_REPORT_ALL_112_MAPPINGS.md` - 100% validation results
- `SESSION_HANDOVER.md` - Session history
- `validate_all_strategy_competency_targets.py` - Validation script

---

## Workaround (If Needed)

If you need to start the backend immediately without these models:

1. Comment out the import in `setup_phase2_task3_for_org.py`:
```python
# from models import StrategyTemplate, LearningStrategy, Organization
```

2. Comment out any code that uses `StrategyTemplate` in routes.py

**WARNING**: This is temporary only! The proper fix is to add the models.

---

## Summary

**What Happened**: Database migration added tables, but Python models were not created
**What's Needed**: Add 2 new models + update 1 existing model in models.py
**Estimated Fix Time**: 10-15 minutes
**Risk**: LOW (copy-paste model definitions from this document)
**Data Loss Risk**: ZERO (only adding Python code, database is intact)

**Next Session Priority**: Fix this FIRST before any other work!
