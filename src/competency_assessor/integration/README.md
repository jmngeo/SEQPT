# SE-QPT + Derik's Competency Assessor Integration

## Overview

This integration seamlessly combines Derik's proven competency assessment system with the SE-QPT qualification planning methodology. The integration preserves all of Derik's original functionality while extending it with Marcel's 4-phase SE qualification planning capabilities and innovative RAG-LLM learning objective generation.

## Architecture

```
SE-QPT Unified System
├── Derik's Competency Assessor (Phase 1 & 2)
│   ├── 16 SE Competencies (KÖNEMANN et al.)
│   ├── 14 Role Clusters
│   ├── Assessment Logic
│   └── LangChain + OpenAI Integration
├── SE-QPT Extensions (Phase 3 & 4)
│   ├── 6 Qualification Archetypes
│   ├── RAG-LLM Learning Objectives
│   ├── Company-specific Context
│   └── Qualification Planning
└── Unified Database Schema
    ├── Preserved Derik Models
    └── Extended SE-QPT Models
```

## Key Integration Components

### 1. Preserved Derik Functionality ✅
- **Original Models**: All Derik's database models preserved
- **Assessment Logic**: Complete competency assessment workflow
- **LangChain Patterns**: Maintained integration patterns
- **OpenAI Models**: Same GPT-4o-mini + text-embedding-ada-002
- **API Compatibility**: All existing endpoints preserved

### 2. SE-QPT Framework Integration ✅
- **16 SE Competencies**: KÖNEMANN et al. framework integrated
- **14 Role Clusters**: Complete role-competency matrix (14×16)
- **6 Qualification Archetypes**: Marcel's strategic approaches
- **Role-Process Matrix**: ISO 15288 process alignment

### 3. RAG-LLM Innovation ✅
- **Learning Objective Generation**: Company-specific objectives
- **Context-Aware Planning**: Industry and company context integration
- **Quality Assessment**: RAG quality scoring and validation
- **Template Customization**: Archetype-based learning formats

## Database Schema

### Derik's Original Models (Preserved)
```sql
-- Core assessment models
RoleCluster
Competency
CompetencyIndicator
IsoSystemLifeCycleProcesses
IsoProcesses
IsoActivities
-- + all other Derik models
```

### SE-QPT Extensions
```sql
-- Qualification planning models
QualificationArchetype     -- 6 strategic approaches
LearningObjective         -- RAG-generated objectives
QualificationPlan         -- Individual plans
RoleCompetencyMatrix      -- 14×16 matrix
CompanyContext           -- Context for RAG generation
```

## API Endpoints

### Derik's Original Endpoints (Preserved)
```
GET  /roles                    -- Get role clusters
GET  /competencies            -- Get competencies
POST /competencies            -- Create competency
...all other Derik endpoints
```

### SE-QPT Extensions
```
GET  /api/se-qpt/archetypes                    -- Get 6 qualification archetypes
POST /api/se-qpt/learning-objectives/generate  -- RAG-generate learning objectives
GET  /api/se-qpt/learning-objectives          -- Get learning objectives
POST /api/se-qpt/qualification-plans          -- Create qualification plan
GET  /api/se-qpt/qualification-plans/:id      -- Get qualification plan
GET  /api/se-qpt/role-competency-matrix       -- Get 14×16 matrix
POST /api/se-qpt/company-context             -- Set company context
GET  /api/se-qpt/status                      -- Integration status
```

## Integration Files

### Core Integration
- `unified_models.py` - Extended database schema
- `se_qpt_routes.py` - SE-QPT API endpoints
- `se_qpt_schema.json` - Integration mapping
- `test_integration.py` - Integration validation

### Data Integration
- `data/processed/corrected_roles_competencies.json` - 14×16 matrix
- `data/processed/correct_qualification_archetypes.json` - 6 archetypes
- `data/processed/se_qpt_complete_backup.json` - Complete data backup

## Usage Examples

### 1. Generate Learning Objectives
```python
# RAG-generate company-specific learning objectives
response = requests.post('/api/se-qpt/learning-objectives/generate', {
    'competency_id': 1,  # Systemic thinking
    'role_id': 6,        # System engineer
    'archetype_id': 4,   # Needs-based, project-oriented training
    'company_context': 'Automotive OEM developing autonomous vehicles...'
})
```

### 2. Create Qualification Plan
```python
# Create personalized qualification plan
response = requests.post('/api/se-qpt/qualification-plans', {
    'user_id': 123,
    'role_id': 6,
    'archetype_id': 4,
    'plan_name': 'SE Competency Development Plan',
    'competency_gaps': {...},  # From Derik's assessment
    'company_context': '...'
})
```

### 3. Access Role-Competency Matrix
```python
# Get the 14×16 role-competency requirements matrix
matrix = requests.get('/api/se-qpt/role-competency-matrix')
```

## Technology Stack

- **Backend**: Flask 3.0 (preserved from Derik)
- **Database**: PostgreSQL with unified schema
- **LLM Integration**: LangChain + OpenAI (same models as Derik)
- **RAG Framework**: ChromaDB + FAISS (compatible with Derik's setup)
- **Frontend**: Vue.js 3 (extended from Derik's patterns)

## Deployment

The integrated system maintains Derik's deployment structure:

```bash
# Start integrated system
cd src/competency_assessor
flask run  # Derik's endpoints + SE-QPT extensions

# Or use Docker
docker-compose up  # Includes both systems
```

## Data Flow

1. **Assessment Phase** (Derik's system)
   - User completes competency assessment
   - System identifies competency gaps
   - Role recommendations generated

2. **Planning Phase** (SE-QPT extension)
   - Select qualification archetype
   - Generate company-specific learning objectives
   - Create personalized qualification plan

3. **RAG-LLM Enhancement**
   - Company context analyzed
   - Learning objectives customized
   - Quality validated and scored

## Quality Assurance

- ✅ All Derik functionality preserved
- ✅ 16 SE competencies integrated
- ✅ 14×16 role-competency matrix validated
- ✅ 6 qualification archetypes confirmed
- ✅ LangChain patterns maintained
- ✅ OpenAI models compatible
- ✅ API backward compatibility ensured

## Next Steps

1. Database migration with unified schema
2. Frontend integration with SE-QPT components
3. RAG knowledge base population
4. Company context collection interface
5. Learning objective quality evaluation system

## Support

For integration issues or questions:
- Review `test_integration.py` validation results
- Check `integration_test_report.json` for detailed status
- Refer to Derik's original documentation for assessment features
- See SE-QPT documentation for qualification planning features