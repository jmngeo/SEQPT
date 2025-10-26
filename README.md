# SE-QPT: Systems Engineering Qualification Planning Tool

A web-based tool for assessing and planning competency development for Systems Engineering roles based on ISO/IEC/IEEE 15288 standards.

## Overview

SE-QPT helps organizations and individuals:
- Identify appropriate SE roles based on task descriptions
- Assess competency levels against 16 core SE competencies
- Generate personalized training recommendations
- Track competency development over time

## Technology Stack

### Backend
- **Framework**: Flask (Python)
- **Database**: PostgreSQL
- **AI/ML**: OpenAI GPT-4 for task-to-role mapping
- **Vector Search**: FAISS for competency matching

### Frontend
- **Framework**: Vue 3 + Composition API
- **UI Library**: Vuetify 3
- **State Management**: Pinia
- **Build Tool**: Vite

## Architecture

### Core Matrices (3-Matrix System)

```
1. ROLE_PROCESS_MATRIX (Customizable per organization)
   - 14 SE Roles × 28 ISO Processes
   - Values: 0-4 (involvement level)
   - Defines which processes each role performs

2. PROCESS_COMPETENCY_MATRIX (Global/Fixed)
   - 28 ISO Processes × 16 Competencies
   - Values: 0-1 (binary requirement)
   - Based on ISO/IEC/IEEE 15288 standards

3. ROLE_COMPETENCY_MATRIX (Auto-calculated)
   - 14 SE Roles × 16 Competencies
   - Values: 0-6 (required proficiency level)
   - Calculated: Role_Process × Process_Competency
```

### Role Identification Approach

SE-QPT uses a **hybrid dual-method** for accurate role matching:

1. **LLM Direct Selection** (Primary)
   - Semantic analysis of task descriptions
   - Context-aware role identification
   - 100% accuracy in validation tests

2. **Euclidean Distance** (Fallback/Validation)
   - Mathematical competency vector comparison
   - Fast and deterministic
   - Provides confidence scores

See `docs/reference/HYBRID_ROLE_SELECTION_APPROACH.md` for details.

## Quick Start

### Prerequisites

- Python 3.9+
- PostgreSQL 12+
- Node.js 16+
- npm 8+

### 1. Clone Repository

```bash
git clone <repository-url>
cd SE-QPT-Master-Thesis
```

### 2. Database Setup

```bash
# Create database and user
createdb -U postgres seqpt_database
psql -U postgres -c "CREATE USER seqpt_admin WITH PASSWORD 'SeQpt_2025';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE seqpt_database TO seqpt_admin;"
```

### 3. Backend Setup

```bash
cd src/backend

# Create virtual environment
python -m venv ../../venv
../../venv/Scripts/activate  # Windows
source ../../venv/bin/activate  # Linux/Mac

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your DATABASE_URL and OPENAI_API_KEY
```

### 4. Initialize Database

See `DATABASE_INITIALIZATION_GUIDE.md` for detailed instructions.

```bash
# Quick setup (run in order)
cd src/backend
python setup/core/init_db_as_postgres.py
python setup/populate/populate_competencies.py
python setup/populate/populate_iso_processes.py
python setup/populate/populate_roles_and_matrices.py
python setup/populate/populate_process_competency_matrix.py
python setup/database_objects/create_stored_procedures.py
```

### 5. Frontend Setup

```bash
cd src/frontend
npm install
```

### 6. Run Application

```bash
# Terminal 1 - Backend
cd src/backend
../../venv/Scripts/activate
python run.py
# Runs on http://localhost:5000

# Terminal 2 - Frontend
cd src/frontend
npm run dev
# Runs on http://localhost:8080
```

## Project Structure

```
SE-QPT-Master-Thesis/
├── src/
│   ├── backend/              # Flask backend
│   │   ├── app/             # Application code
│   │   │   ├── routes.py    # Main API endpoints
│   │   │   ├── services/    # Business logic
│   │   │   └── ...
│   │   ├── models.py        # SQLAlchemy models
│   │   ├── run.py           # Application entry point
│   │   ├── setup/           # Database setup scripts
│   │   │   ├── core/        # DB initialization
│   │   │   ├── populate/    # Reference data
│   │   │   └── ...
│   │   └── archive/         # Historical/debug scripts
│   │
│   └── frontend/            # Vue 3 frontend
│       ├── src/
│       │   ├── views/       # Page components
│       │   ├── components/  # Reusable components
│       │   ├── stores/      # Pinia state stores
│       │   └── api/         # API client
│       └── ...
│
├── data/                    # Reference data
├── docs/                    # Documentation
│   ├── reference/           # Technical references
│   └── archive/             # Historical documentation
├── venv/                    # Python virtual environment
├── DATABASE_INITIALIZATION_GUIDE.md
├── NEW_MACHINE_SETUP_GUIDE.md
├── SESSION_HANDOVER.md      # Session continuity tracking
└── README.md               # This file
```

## Key Features

### Phase 1: Role Identification
- Task-based role mapping using LLM
- Standard role selection from 14 SE role clusters
- Target group size configuration

### Phase 2: Competency Assessment
- Assessment of 16 SE competencies
- Integration with role-specific requirements
- Maturity level evaluation (0-6 scale)

### Phase 3: Training Recommendations
- Personalized learning paths
- Module library integration
- Gap analysis and prioritization

## Documentation

### Essential Guides
- `DATABASE_INITIALIZATION_GUIDE.md` - Complete database setup reference
- `NEW_MACHINE_SETUP_GUIDE.md` - First-time environment setup
- `SESSION_HANDOVER.md` - Development session history and context

### Technical References
- `docs/reference/HYBRID_ROLE_SELECTION_APPROACH.md` - Role matching methodology
- `docs/reference/MATRIX_CALCULATION_PATTERN.md` - Matrix calculation logic
- `docs/reference/DERIK_INTEGRATION_ANALYSIS.md` - Integration architecture
- `docs/reference/TASK_BASED_ROLE_MATCHING_SOLUTION.md` - Task analysis approach

### Archived Documentation
- `docs/archive/cleanup/` - Codebase refactoring history
- `docs/archive/features/` - Feature implementation summaries
- `docs/archive/fixes/` - Bug fix analyses
- `docs/archive/migrations/` - One-time migration documentation
- `docs/archive/planning/` - Completed planning documents

## Database Schema

### Core Tables
- `competency` - 16 SE competencies
- `iso_process` - 28 ISO/IEC/IEEE 15288 processes
- `role_cluster` - 14 SE role definitions
- `organization` - Multi-tenant support

### Matrix Tables
- `role_process_matrix` - Role-to-process involvement levels
- `process_competency_matrix` - Process-to-competency requirements
- `role_competency_matrix` - Calculated role competency requirements

### User & Assessment Tables
- `user` - User accounts and profiles
- `assessment` - Competency assessment records
- `assessment_history` - Assessment tracking over time

## Environment Variables

```bash
# Database
DATABASE_URL=postgresql://seqpt_admin:SeQpt_2025@localhost:5432/seqpt_database

# Flask
FLASK_APP=run.py
FLASK_DEBUG=1
SECRET_KEY=your-secret-key-here

# OpenAI
OPENAI_API_KEY=your-openai-api-key
```

## Development Notes

### Windows-Specific Considerations
- This project runs on Windows OS
- Use Windows-compatible path separators: `\` (though `/` often works)
- Console encoding is `charmap` (cp1252) - avoid Unicode/emoji in logs
- Flask hot-reload may not work reliably - restart server manually

### Important Guidelines
1. **Always check SESSION_HANDOVER.md first** when starting a new session
2. **Restart Flask server manually** after code changes (hot-reload unreliable)
3. **Never use emojis** in code/logs (encoding issues)
4. **Reference Derik's implementation** for competency assessment logic

### Common Issues

See `DATABASE_INITIALIZATION_GUIDE.md` for detailed troubleshooting, including:
- 404 on survey submission (trigger issues)
- All competency scores showing 0 or 6 (insufficient task input)
- Empty max_scores array (stored procedure verification)
- Unicode errors (emoji usage)

## Testing

### Validation Test Profiles
Located in `docs/archive/` (removed from root):
- Test profiles validate role matching accuracy
- 100% accuracy achieved with LLM-based approach

## Contributing

When contributing:
1. Check `SESSION_HANDOVER.md` for latest session context
2. Update `SESSION_HANDOVER.md` with your changes
3. Follow existing code patterns and architecture
4. Test on Windows environment
5. Avoid Unicode characters in code

## License

[Add license information]

## Authors

- Jomon [Student]
- Based on original work by Derik

## Acknowledgments

- ISO/IEC/IEEE 15288 Systems Engineering Standards
- OpenAI GPT-4 for semantic role matching
- FAISS for efficient vector similarity search
