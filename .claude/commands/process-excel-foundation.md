# Process Excel Foundation Data

Extract and validate all data from the foundational Excel file containing SE matrices and templates.

## Command Actions:
1. Validate Excel file structure (6+ sheets required)
2. Extract Role-Competency Matrix (14×16)
3. Process Qualification Archetypes (6 strategies)
4. Load Learning Objectives Templates
5. Import SE Competence Modules
6. Create Process-Competency mappings
7. Validate data integrity and relationships
8. Generate data quality report
9. Load into PostgreSQL database
10. Create JSON backups for inspection

## Input File:
`data/source/excel/Qualifizierungsmodule_Qualifizierungspläne_v4_enUS.xlsx`

## Output:
- PostgreSQL tables populated with SE data
- JSON files in data/processed/
- Data validation report
- RAG knowledge base prepared
