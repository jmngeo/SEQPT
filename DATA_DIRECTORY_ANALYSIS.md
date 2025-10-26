# SE-QPT Data Directory - Comprehensive Analysis
**Date:** 2025-10-26
**Purpose:** Document all files in `/data` directory - their purpose, usage, and necessity

---

## Executive Summary

The `/data` directory contains **50+ files** across multiple categories:
- **3 files** actively loaded at runtime (CRITICAL)
- **10 files** used for database initialization/setup
- **15 files** for reference/documentation
- **12 files** historical/backup versions
- **5 PDF files** (10.7 MB) for thesis research
- **1 SQLite database** for RAG vector embeddings

**Total Size:** ~15 MB (excluding venv)

---

## Category 1: CRITICAL RUNTIME FILES ✅ KEEP

These files are **loaded every time the application runs** and are essential for operation:

### 1.1 Learning Objectives Generation (Phase 3)
| File | Size | Used By | Purpose |
|------|------|---------|---------|
| `processed/archetype_competency_matrix.json` | 219 lines | `learning_objectives_generator.py:17` | Maps qualification archetypes to target competency levels (0-5 scale) |
| `source/templates/learning_objectives_guidelines.json` | 110 lines | `learning_objectives_generator.py:18` | SMART criteria, action verbs, templates for LLM-based learning objective generation |

**Status:** **CRITICAL** - Required for Phase 3 learning objectives generation

### 1.2 RAG System (Phase 2)
| File | Size | Used By | Purpose |
|------|------|---------|---------|
| `processed/se_foundation_data.json` | 763 lines | `rag_pipeline.py:177` | Foundation SE knowledge for RAG system (fallback when vector DB unavailable) |
| `rag_vectordb/chroma.sqlite3` | SQLite DB | `rag_pipeline.py:75` | ChromaDB vector embeddings for competency assessment |

**Status:** **CRITICAL** - Required for Phase 2 competency assessment RAG-LLM

### 1.3 Standard Learning Objectives
| File | Size | Used By | Purpose |
|------|------|---------|---------|
| `processed/standard_learning_objectives.json` | 347 lines | Potentially used by RAG | Pre-defined learning objectives by competency and level (Excel scale: 1,2,4,6) |

**Status:** **IMPORTANT** - May be used by RAG or LLM for generating context-aware objectives

**Total Critical Files:** 5 files

---

## Category 2: SETUP & INITIALIZATION FILES 📋 KEEP

Files used for **database initialization** or **new machine deployment**:

### 2.1 Excel Data Source
| File | Size | Purpose |
|------|------|---------|
| `source/excel/Qualifizierungsmodule_Qualifizierungspläne_v4_enUS.xlsx` | N/A | Source Excel file for role-competency matrix, modules, processes |
| `source/excel/excel_config.json` | 17 lines | Configuration for Excel parsing scripts |
| `source/excel/README.md` | Doc | Documentation for Excel structure |

**Used By:**
- `archive/debug/compare_role_competency_sources.py`
- `archive/debug/inspect_excel.py`

**Status:** **KEEP** - Required for data extraction and validation

### 2.2 Questionnaire Templates
| File | Size | Purpose |
|------|------|---------|
| `source/questionnaires/phase1/archetype_selection.json` | 116 lines | Phase 1 archetype selection questionnaire |
| `source/questionnaires/phase1/maturity_assessment.json` | 61 lines | Phase 1 maturity assessment questionnaire |
| `source/questionnaires/phase2/competency_assessment.json` | 43 lines | Phase 2 competency assessment questionnaire |
| `source/questionnaires/phase2/se_qpt_learning_objectives_template.json` | 288 lines | Phase 3 learning objectives template |

**Status:** **REFERENCE** - Not currently loaded by backend code. May be used by frontend or future features.

### 2.3 Database Reference Data
| File | Size | Purpose |
|------|------|---------|
| `processed/role_competency_matrix.json` | 639 lines | Role-competency matrix (now in PostgreSQL database) |
| `processed/modules_mappings.json` | 3616 lines | Learning modules to competencies mapping (for Phase 4?) |

**Status:** **ARCHIVE** - Data is in database. Keep for backup/reference only.

**Total Setup Files:** 10 files

---

## Category 3: REFERENCE & DOCUMENTATION 📚 KEEP

Files that document the system design and provide reference information:

### 3.1 System Architecture Documentation
| File | Type | Purpose |
|------|------|---------|
| `Archetype_or_Strategy_Architecture.md` | Doc | Explains qualification archetype vs strategy design |
| `SE Qualification Strategies Classification.md` | Doc | Classification of SE qualification strategies |
| `se_qpt_user_architecture.md` | Doc | User architecture and workflow |
| `SE-QPT Comprehensive Workflow.md` | Doc | Complete workflow documentation |
| `SE-QPT Questionnaire Implementation Guide.md` | Doc | Questionnaire implementation guide |
| `SE-QPT_Derik_Integration_Analysis.md` | Doc | Analysis of Derik's competency assessor integration |
| `derik-design-implementation.md` | Doc | Derik's system design and implementation details |

**Status:** **DOCUMENTATION** - Essential for understanding system design

### 3.2 Data Processing Documentation
| File | Size | Purpose |
|------|------|---------|
| `processed/COMPETENCY_LEVEL_SCALES.md` | 125 lines | **CRITICAL DOC** - Explains two different competency scales and conversion |
| `processed/data_summary.json` | 19 lines | Summary of processed data counts |
| `processed/validation_report.json` | 35 lines | Data validation report from Excel extraction |
| `processed/qualification_archetype_analysis.json` | 37 lines | Analysis of qualification archetypes |

**Status:** **REFERENCE** - Important for understanding data structure

### 3.3 Competency & Module Reference
| File | Purpose |
|------|---------|
| `source/SE Competency Modules.md` | SE competency modules description |
| `source/templates/archetypes/project_oriented_training.json` | Example archetype template |
| `source/templates/competencies/systems_thinking.json` | Example competency template |

**Status:** **REFERENCE/EXAMPLES** - Used as examples for generation

### 3.4 Questionnaire Documentation
| File | Purpose |
|------|---------|
| `source/questionnaires/Complete SE-QPT Questionnaire Set.md` | Complete questionnaire documentation |

**Status:** **DOCUMENTATION**

**Total Reference Files:** 15 files

---

## Category 4: HISTORICAL & BACKUP FILES 📦 ARCHIVE/DELETE

Old versions, backups, and deprecated files:

### 4.1 Old Questionnaire Versions
| File | Status |
|------|--------|
| `source/questionnaires/phase1/archetype_selection_backup_old.json` | **DELETE** - Superseded by current version |
| `source/questionnaires/phase1/maturity_assessment_backup_old.json` | **DELETE** - Superseded by current version |
| `source/questionnaires/phase1/seqpt_maturity_complete_reference_final.json` | **KEEP** - Final reference version |

### 4.2 Phase 1 Development Files
**Directory:** `source/Phase 1 changes/`

| File | Purpose | Status |
|------|---------|--------|
| `seqpt_maturity_complete_reference.json` | Improved maturity system v2.0 | **KEEP** - Reference for Phase 1 implementation |
| `Phase_1_Complete_Implementation_Instructions.md` | Implementation instructions | **ARCHIVE** - Historical development docs |
| `phase1-restructure-instructions-task2.md` | Task 2 instructions | **ARCHIVE** |
| `SE-QPT_Project_Refactoring_Instructions.md` | Refactoring guide | **ARCHIVE** |
| `se-qpt-task3-implementation.md` | Task 3 implementation | **ARCHIVE** |
| `claude_instructions.md` | Claude AI instructions | **ARCHIVE** |
| `Decision Tree.png` | Decision tree visualization | **KEEP** - Visual reference |

**Status:** **ARCHIVE** - Historical development documentation

### 4.3 Old Phase 1 Files
**Directory:** `source/questionnaires/phase 1 - to update/`

| File | Status |
|------|--------|
| `final-validated-questionnaires.json` | **KEEP** - Validated reference |
| `old_se-qpt-claude-code-instructions.md` | **ARCHIVE** - Old instructions |
| `old_updated-se-qpt-questionnaires.md` | **ARCHIVE** - Old questionnaires |

### 4.4 Corrected/Updated Versions
| File | Status |
|------|--------|
| `processed/role_competency_matrix_corrected.json` | **KEEP** - Documents correction history |
| `processed/corrected_roles_competencies.json` | **KEEP** - Correction reference |
| `processed/correct_qualification_archetypes.json` | **KEEP** - Corrected archetype list |

### 4.5 Complete Backup
| File | Size | Purpose |
|------|------|---------|
| `processed/se_qpt_complete_backup.json` | 5064 lines | Complete backup of all Excel data extraction (2025-09-22) |

**Status:** **KEEP** - Comprehensive backup for disaster recovery

**Total Historical Files:** 12 files

---

## Category 5: THESIS RESEARCH FILES 🎓 KEEP

Academic source materials and research documents:

### 5.1 Master Thesis PDFs
| File | Size | Author | Purpose |
|------|------|--------|---------|
| `Masterarbeit Marcel Niemeyer_7118380_final en-US.pdf` | 2.8 MB | Marcel Niemeyer | **PRIMARY** - 4-phase SE-QPT methodology source |
| `DerikRoby_MasterThesis_Design_Section.pdf` | 376 KB | Derik Roby | Phase 2 competency assessor design |
| `DerikRoby_MasterThesis_Evaluation_Summary.pdf` | 2.5 MB | Derik Roby | Competency assessor evaluation |
| `Sachin_Kumar_Master_Thesis_6906625.pdf` | 4.7 MB | Sachin Kumar | Learning format selection research |
| `Thesis_Proposal_Final.pdf` | 284 KB | Current project | Project objectives and scope |

**Total Size:** 10.7 MB

### 5.2 Thesis Documentation
| File | Purpose |
|------|---------|
| `source/thesis_files/README.md` | Index of research documents and integration approach |
| `source/thesis_files/integration_config.json` | Integration configuration |

**Status:** **KEEP** - Required for:
- Academic citations and references
- Methodology validation
- System design justification
- Research context

**Total Thesis Files:** 7 files

---

## File Type Summary

| Type | Count | Total Size | Keep/Archive |
|------|-------|------------|--------------|
| JSON (active runtime) | 5 | ~1 MB | **KEEP** |
| JSON (setup/reference) | 15 | ~4 MB | **KEEP** |
| JSON (historical) | 8 | ~5 MB | **ARCHIVE** |
| Markdown (documentation) | 15 | ~100 KB | **KEEP** |
| PDF (thesis research) | 5 | 10.7 MB | **KEEP** |
| Excel (source data) | 1 | N/A | **KEEP** |
| SQLite (vector DB) | 1 | N/A | **KEEP** |
| PNG (diagrams) | 1 | N/A | **KEEP** |

**Total:** 51 files, ~15 MB

---

## Recommendations

### ✅ KEEP (Essential)
1. All runtime JSON files (5 files)
2. Excel source file and config
3. All markdown documentation
4. Thesis PDF files
5. Vector database
6. Complete backup file
7. Final/reference questionnaire versions

### 📦 ARCHIVE (Move to `/data/archive/`)
1. `*_backup_old.json` files (2 files)
2. `source/Phase 1 changes/` development docs (6 files)
3. `source/questionnaires/phase 1 - to update/old_*` files (2 files)

### 🗑️ SAFE TO DELETE
1. Duplicate backup files if complete backup exists
2. Old instruction/guide markdown files (once archived)

### 🔄 REORGANIZE SUGGESTION

```
data/
├── runtime/              # Files loaded at runtime
│   ├── archetype_competency_matrix.json
│   ├── learning_objectives_guidelines.json
│   ├── se_foundation_data.json
│   └── standard_learning_objectives.json
├── setup/                # Database initialization
│   ├── excel/
│   └── questionnaires/
├── reference/            # Documentation & examples
│   ├── docs/
│   ├── templates/
│   └── validation/
├── backup/               # Backups
│   └── se_qpt_complete_backup.json
├── research/             # Thesis materials
│   └── thesis_files/
└── archive/              # Historical files
    └── phase1_development/
```

---

## Database vs Files

**Data in PostgreSQL Database (No JSON needed):**
- ISO/IEC 15288 Processes (28 entries)
- SE Competencies (16 entries)
- SE Roles (14 entries)
- Role-Process Matrix (392 entries)
- Process-Competency Matrix (448 entries)
- Role-Competency Matrix (224 entries per org)

**Data in JSON Files (Required at runtime):**
- Archetype-Competency Matrix (not in DB)
- Learning Objectives Guidelines (not in DB)
- SE Foundation Data (for RAG fallback)
- Standard Learning Objectives (templates)

**Data in Vector Database:**
- SE knowledge embeddings (ChromaDB)
- Used for RAG-based competency assessment

---

## New Machine Setup Checklist

To deploy SE-QPT on a new machine, you need:

### Required Files:
1. ✅ `data/source/excel/Qualifizierungsmodule_Qualifizierungspläne_v4_enUS.xlsx`
2. ✅ `data/processed/archetype_competency_matrix.json`
3. ✅ `data/source/templates/learning_objectives_guidelines.json`
4. ✅ `data/processed/se_foundation_data.json`
5. ✅ `data/rag_vectordb/` (entire directory)
6. ✅ `.env` file with credentials
7. ✅ Database initialization scripts in `src/backend/setup/`

### Optional (for reference):
- Documentation markdown files
- Thesis PDF files
- Questionnaire templates

---

## Usage in Code

### Backend Python Files That Load JSON:
1. `src/backend/app/learning_objectives_generator.py`
   - Loads: `archetype_competency_matrix.json`
   - Loads: `learning_objectives_guidelines.json`

2. `src/backend/app/services/rag/rag_pipeline.py`
   - Loads: `se_foundation_data.json` (fallback)
   - Uses: `rag_vectordb/` (primary)

3. `src/backend/archive/debug/compare_role_competency_sources.py`
   - Loads: Excel file (debug only)

### Frontend Files:
- **None** - Frontend loads questionnaires from **backend API**, not directly from JSON files

### Database Initialization:
- `src/backend/setup/populate/initialize_all_data.py` - Uses hardcoded Python data, not JSON

---

## Key Insights

1. **Only 3-5 JSON files are actively loaded at runtime**
2. **PostgreSQL database is the primary source of truth** after initialization
3. **Questionnaire JSON files are reference only** - not loaded by backend
4. **RAG vector database is critical** for Phase 2 competency assessment
5. **Excel file is the canonical source** for role-competency-process matrices
6. **Two different competency scales exist** - see COMPETENCY_LEVEL_SCALES.md

---

## Critical Discovery: Two Competency Scales

**See `processed/COMPETENCY_LEVEL_SCALES.md` for details**

- **Excel Scale:** 0, 1, 2, 4, 6 (used in database and standard learning objectives)
- **Archetype Scale:** 0-5 (used in archetype_competency_matrix.json)

**Conversion required** when matching archetype levels to learning objectives!

---

**Document Status:** Complete
**Last Updated:** 2025-10-26
**Reviewed By:** Claude Code Analysis
