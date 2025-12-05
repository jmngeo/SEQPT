# SE-QPT Documentation Index

**Last Updated:** 2025-12-05

This document provides a navigational guide to all documentation in the SE-QPT project.

---

## Quick Links

| Document | Purpose | Location |
|----------|---------|----------|
| README | Project overview & quick start | [README.md](../README.md) |
| Session Handover | Current session state & continuity | [SESSION_HANDOVER.md](../SESSION_HANDOVER.md) |
| Backlog | Outstanding tasks & features | [BACKLOG.md](../BACKLOG.md) |
| Database Setup | Complete DB initialization guide | [DATABASE_INITIALIZATION_GUIDE.md](../DATABASE_INITIALIZATION_GUIDE.md) |
| Deployment | Deployment validation checklist | [DEPLOYMENT_CHECKLIST.md](../DEPLOYMENT_CHECKLIST.md) |

---

## Documentation Structure

```
SE-QPT-Master-Thesis/
|-- README.md                      # Project overview
|-- SESSION_HANDOVER.md            # Session continuity tracking
|-- BACKLOG.md                     # Outstanding tasks
|-- DATABASE_INITIALIZATION_GUIDE.md
|-- DEPLOYMENT_CHECKLIST.md
|
|-- docs/
|   |-- DOCUMENTATION_INDEX.md     # This file
|   |-- ARCHIVE_HISTORY.md         # Consolidated historical docs
|   |-- reference/                 # Active reference documentation
|       |-- SE-QPT_DESIGN_SUMMARY_FOR_ADVISOR.md
|       |-- DERIK_INTEGRATION_ANALYSIS.md
|       |-- HYBRID_ROLE_SELECTION_APPROACH.md
|       |-- MATRIX_CALCULATION_PATTERN.md
|       |-- TASK_BASED_ROLE_MATCHING_SOLUTION.md
|       |-- TRAINING_METHODS.md
|       |-- DISTRIBUTION_SCENARIO_ANALYSIS.md
|       |-- PHASE3_FORMAT_RECS_DESIGN_INPUTS.md
|
|-- data/source/
|   |-- Phase 2/                   # Current Phase 2 design docs
|       |-- LEARNING_OBJECTIVES_DESIGN_V5_COMPREHENSIVE*.md (3 parts)
|       |-- LEARNING_OBJECTIVES_STEP_BY_STEP_GUIDE.md
|       |-- LEARNING_OBJECTIVES_ALGORITHM_SUMMARY.md
|       |-- Reference guide for thesis advisor/
|
|-- archive/                       # Historical/archived content
    |-- code_backups/              # Legacy code snapshots
    |-- docs_snapshots/            # Historical documentation
    |-- phase2_lo_design_history/  # Old LO design versions (v1-v4)
    |-- scripts/                   # One-time utility scripts
```

---

## Reference Documentation

### Architecture & Design

| Document | Description |
|----------|-------------|
| [SE-QPT_DESIGN_SUMMARY_FOR_ADVISOR.md](reference/SE-QPT_DESIGN_SUMMARY_FOR_ADVISOR.md) | Comprehensive design overview for thesis advisor |
| [DERIK_INTEGRATION_ANALYSIS.md](reference/DERIK_INTEGRATION_ANALYSIS.md) | Integration with Derik's competency assessment |
| [HYBRID_ROLE_SELECTION_APPROACH.md](reference/HYBRID_ROLE_SELECTION_APPROACH.md) | Role matching methodology |
| [MATRIX_CALCULATION_PATTERN.md](reference/MATRIX_CALCULATION_PATTERN.md) | Matrix calculation logic |
| [TASK_BASED_ROLE_MATCHING_SOLUTION.md](reference/TASK_BASED_ROLE_MATCHING_SOLUTION.md) | Task analysis approach |

### Phase 2 Learning Objectives (Current)

| Document | Description |
|----------|-------------|
| [LEARNING_OBJECTIVES_DESIGN_V5_COMPREHENSIVE.md](../data/source/Phase%202/LEARNING_OBJECTIVES_DESIGN_V5_COMPREHENSIVE.md) | V5 comprehensive design (Part 1) |
| [LEARNING_OBJECTIVES_DESIGN_V5_COMPREHENSIVE_PART2.md](../data/source/Phase%202/LEARNING_OBJECTIVES_DESIGN_V5_COMPREHENSIVE_PART2.md) | V5 design (Part 2) |
| [LEARNING_OBJECTIVES_DESIGN_V5_COMPREHENSIVE_PART3_FINAL.md](../data/source/Phase%202/LEARNING_OBJECTIVES_DESIGN_V5_COMPREHENSIVE_PART3_FINAL.md) | V5 design (Part 3 - Final) |
| [LEARNING_OBJECTIVES_STEP_BY_STEP_GUIDE.md](../data/source/Phase%202/LEARNING_OBJECTIVES_STEP_BY_STEP_GUIDE.md) | Implementation guide |
| [LEARNING_OBJECTIVES_ALGORITHM_SUMMARY.md](../data/source/Phase%202/LEARNING_OBJECTIVES_ALGORITHM_SUMMARY.md) | Algorithm overview |

### Phase 3 Planning (Future)

| Document | Description |
|----------|-------------|
| [TRAINING_METHODS.md](reference/TRAINING_METHODS.md) | Catalog of SE training approaches |
| [DISTRIBUTION_SCENARIO_ANALYSIS.md](reference/DISTRIBUTION_SCENARIO_ANALYSIS.md) | Competency distribution patterns |
| [PHASE3_FORMAT_RECS_DESIGN_INPUTS.md](reference/PHASE3_FORMAT_RECS_DESIGN_INPUTS.md) | Phase 3 design requirements |

### For Thesis Advisor

| Document | Description |
|----------|-------------|
| [ADVISOR_DOCUMENTATION_INDEX.md](../data/source/Phase%202/Reference%20guide%20for%20thesis%20advisor/ADVISOR_DOCUMENTATION_INDEX.md) | Index for advisor review |
| [LEARNING_OBJECTIVES_EXECUTIVE_SUMMARY.md](../data/source/Phase%202/Reference%20guide%20for%20thesis%20advisor/LEARNING_OBJECTIVES_EXECUTIVE_SUMMARY.md) | Non-technical summary |
| [LEARNING_OBJECTIVES_VISUAL_FLOWCHARTS.md](../data/source/Phase%202/Reference%20guide%20for%20thesis%20advisor/LEARNING_OBJECTIVES_VISUAL_FLOWCHARTS.md) | Visual explanations |
| [MAIN_ALGORITHM.md](../data/source/Phase%202/Reference%20guide%20for%20thesis%20advisor/MAIN_ALGORITHM.md) | Algorithm reference |

---

## Archive Contents

### docs/ARCHIVE_HISTORY.md

Consolidated documentation from 78 historical files, organized by category:
- **Historical**: Session completion summaries, implementation status
- **Cleanup**: Code refactoring documentation
- **Features**: Feature implementation summaries
- **Fixes**: Bug fix analyses and root cause documentation
- **Migrations**: Database and UI migration guides
- **Planning**: Completed planning documents

### archive/ Directory

| Subdirectory | Contents |
|--------------|----------|
| `code_backups/` | Legacy backend, frontend, RAG, routes backups |
| `docs_snapshots/` | Historical documentation snapshots |
| `phase2_lo_design_history/` | LO design versions v1-v4, old flowcharts |
| `scripts/` | One-time utility and migration scripts |

---

## External Backups

The following large backup was moved outside the repository:

**Location:** `../SE-QPT-External-Backups/archives/`

Contains:
- `competency_assessor_20251020/` - Full October 2025 snapshot
- `competency_assessor_backup_20251020/` - Duplicate snapshot

Total size: ~322MB (includes node_modules)

---

## Documentation Guidelines

### When to Create New Docs

1. **New feature design** - Create in `docs/reference/` or appropriate `data/source/Phase X/`
2. **Bug fix analysis** - If significant, add to `SESSION_HANDOVER.md`; archive when resolved
3. **Meeting notes** - Add to `data/Meeting notes/`; consolidate periodically
4. **Historical/completed work** - Move to `archive/` or add to `ARCHIVE_HISTORY.md`

### Naming Conventions

- Use UPPERCASE_WITH_UNDERSCORES for documentation files
- Include date suffix for versioned docs: `_YYYY-MM-DD.md`
- Prefix archived versions with `old_` or move to `archive/`

### What NOT to Do

- Don't create root-level docs for small fixes
- Don't keep multiple versions of the same design doc active
- Don't store large backups in the repository
