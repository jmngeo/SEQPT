"""
Comprehensive analysis of model definitions vs populate scripts.
Ensures database schema and populate functions are in sync.
"""

import os
import re
import ast
from collections import defaultdict

# Get model fields from models.py
def extract_model_fields(models_file='models.py'):
    """Extract all model class definitions and their fields."""
    with open(models_file, 'r', encoding='utf-8') as f:
        content = f.read()

    models = {}
    current_model = None
    current_tablename = None

    for line in content.split('\n'):
        # Detect class definition
        if line.strip().startswith('class ') and 'db.Model' in line:
            match = re.match(r'class\s+(\w+)\(', line)
            if match:
                current_model = match.group(1)
                models[current_model] = {
                    'fields': [],
                    'tablename': None,
                    'relationships': []
                }

        # Get table name
        if current_model and '__tablename__' in line:
            match = re.search(r"__tablename__\s*=\s*['\"](\w+)['\"]", line)
            if match:
                models[current_model]['tablename'] = match.group(1)

        # Get column definitions
        if current_model and '= db.Column(' in line:
            match = re.match(r'\s+(\w+)\s*=\s*db\.Column\(', line)
            if match:
                field_name = match.group(1)

                # Extract column type
                type_match = re.search(r'db\.(\w+)\(', line)
                field_type = type_match.group(1) if type_match else 'Unknown'

                # Check constraints
                nullable = 'nullable=False' in line
                primary_key = 'primary_key=True' in line
                unique = 'unique=True' in line
                foreign_key = 'db.ForeignKey(' in line

                fk_target = None
                if foreign_key:
                    fk_match = re.search(r"db\.ForeignKey\(['\"]([^'\"]+)['\"]", line)
                    if fk_match:
                        fk_target = fk_match.group(1)

                models[current_model]['fields'].append({
                    'name': field_name,
                    'type': field_type,
                    'nullable': nullable,
                    'primary_key': primary_key,
                    'unique': unique,
                    'foreign_key': fk_target
                })

    return models


def extract_populate_operations(populate_files):
    """Extract what fields each populate script tries to insert."""
    operations = {}

    for pop_file in populate_files:
        if not os.path.exists(pop_file):
            continue

        with open(pop_file, 'r', encoding='utf-8') as f:
            content = f.read()

        operations[pop_file] = {
            'models_used': [],
            'fields_inserted': defaultdict(list),
            'queries': []
        }

        # Find model instantiations
        # Pattern: ModelName(...fields...)
        model_pattern = r'(\w+)\('

        # Find INSERT statements
        insert_pattern = r'INSERT\s+INTO\s+(\w+)\s*\(([\w\s,]+)\)'

        for match in re.finditer(model_pattern, content):
            model_name = match.group(1)
            # Check if it's likely a model class (starts with capital)
            if model_name[0].isupper() and model_name not in ['Column', 'String', 'Integer', 'DateTime', 'Boolean', 'Float', 'Text']:
                if model_name not in operations[pop_file]['models_used']:
                    operations[pop_file]['models_used'].append(model_name)

        # Find raw SQL inserts
        for match in re.finditer(insert_pattern, content, re.IGNORECASE):
            table_name = match.group(1)
            fields = [f.strip() for f in match.group(2).split(',')]
            operations[pop_file]['fields_inserted'][table_name].extend(fields)
            operations[pop_file]['queries'].append({
                'table': table_name,
                'fields': fields
            })

    return operations


def check_model_sync():
    """Main analysis function."""
    print("=" * 80)
    print("MODEL-POPULATE SYNCHRONIZATION ANALYSIS")
    print("=" * 80)

    # Extract models
    print("\n[1/4] Extracting model definitions from models.py...")
    models = extract_model_fields()
    print(f"  Found {len(models)} model classes")

    # Get populate files
    populate_files = [
        'populate_competencies.py',
        'populate_iso_processes.py',
        'populate_roles_and_matrices.py',
        'populate_org11_matrices.py',
        'populate_org11_role_competency_matrix.py',
        'populate_process_competency_matrix.py',
        'create_role_competency_matrix.py',
        'create_stored_procedures.py'
    ]

    print("\n[2/4] Analyzing populate scripts...")
    operations = extract_populate_operations(populate_files)
    print(f"  Analyzed {len([k for k,v in operations.items() if v['models_used'] or v['queries']])} active scripts")

    # Analysis
    print("\n[3/4] Comparing models with populate operations...")

    issues = []

    # Check each model
    for model_name, model_info in models.items():
        tablename = model_info['tablename']

        if not tablename:
            continue

        # Find which populate scripts touch this model/table
        related_scripts = []
        for script, ops in operations.items():
            if model_name in ops['models_used']:
                related_scripts.append(script)
            for query in ops['queries']:
                if query['table'] == tablename:
                    related_scripts.append(script)

        if related_scripts:
            model_info['populate_scripts'] = list(set(related_scripts))

    # Summary report
    print("\n[4/4] Generating report...")
    print("\n" + "=" * 80)
    print("CORE MODELS SUMMARY")
    print("=" * 80)

    core_models = [
        'Organization', 'Competency', 'RoleCluster', 'IsoProcesses',
        'IsoActivities', 'IsoTasks', 'RoleProcessMatrix',
        'ProcessCompetencyMatrix', 'RoleCompetencyMatrix',
        'UnknownRoleProcessMatrix', 'UnknownRoleCompetencyMatrix'
    ]

    for model_name in core_models:
        if model_name not in models:
            print(f"\n[WARNING] Model {model_name} not found!")
            continue

        model = models[model_name]
        print(f"\n{model_name} (table: {model['tablename']})")
        print(f"  Fields: {len(model['fields'])}")

        # Show fields
        for field in model['fields'][:5]:  # Show first 5
            constraints = []
            if field['primary_key']:
                constraints.append('PK')
            if not field['nullable']:
                constraints.append('NOT NULL')
            if field['unique']:
                constraints.append('UNIQUE')
            if field['foreign_key']:
                constraints.append(f'FK->{field["foreign_key"]}')

            constraint_str = f" [{', '.join(constraints)}]" if constraints else ""
            print(f"    - {field['name']}: {field['type']}{constraint_str}")

        if len(model['fields']) > 5:
            print(f"    ... and {len(model['fields']) - 5} more fields")

        # Show populate scripts
        if 'populate_scripts' in model:
            print(f"  Populated by: {len(model['populate_scripts'])} script(s)")
            for script in model['populate_scripts']:
                print(f"    - {os.path.basename(script)}")
        else:
            print(f"  [INFO] No populate scripts found")

    # Check for recent additions
    print("\n" + "=" * 80)
    print("PHASE 1 / TASK-BASED MODELS")
    print("=" * 80)

    phase1_models = [
        'User', 'MaturityAssessment', 'QualificationArchetype',
        'PhaseQuestionnaireResponse', 'UserCompetencySurveyResult'
    ]

    for model_name in phase1_models:
        if model_name in models:
            model = models[model_name]
            print(f"\n{model_name} (table: {model['tablename']})")
            print(f"  Fields: {len(model['fields'])}")

            # Check for specific Phase 1 fields
            field_names = [f['name'] for f in model['fields']]

            if model_name == 'User':
                required_fields = ['username', 'email', 'organization_id']
                for req in required_fields:
                    status = "[OK]" if req in field_names else "[MISSING]"
                    print(f"    {status} {req}")

            if 'populate_scripts' in model:
                print(f"  Populated by: {', '.join([os.path.basename(s) for s in model['populate_scripts']])}")

    # Check for missing relationships
    print("\n" + "=" * 80)
    print("FOREIGN KEY RELATIONSHIPS")
    print("=" * 80)

    fk_count = 0
    for model_name, model in models.items():
        fks = [f for f in model['fields'] if f['foreign_key']]
        if fks:
            fk_count += len(fks)
            print(f"\n{model_name}:")
            for fk in fks:
                print(f"  {fk['name']} -> {fk['foreign_key']}")

    print(f"\nTotal foreign keys: {fk_count}")

    # Populate script coverage
    print("\n" + "=" * 80)
    print("POPULATE SCRIPT COVERAGE")
    print("=" * 80)

    for script, ops in operations.items():
        if ops['models_used'] or ops['queries']:
            print(f"\n{os.path.basename(script)}:")
            if ops['models_used']:
                print(f"  Models used: {', '.join(ops['models_used'])}")
            if ops['queries']:
                print(f"  SQL operations: {len(ops['queries'])}")
                for q in ops['queries'][:3]:  # Show first 3
                    print(f"    - INSERT INTO {q['table']} ({len(q['fields'])} fields)")

    # Critical checks
    print("\n" + "=" * 80)
    print("CRITICAL CHECKS")
    print("=" * 80)

    critical_tables = {
        'competency': 'Competency',
        'role_cluster': 'RoleCluster',
        'iso_processes': 'IsoProcesses',
        'role_process_matrix': 'RoleProcessMatrix',
        'process_competency_matrix': 'ProcessCompetencyMatrix',
        'role_competency_matrix': 'RoleCompetencyMatrix'
    }

    all_good = True
    for tablename, modelname in critical_tables.items():
        if modelname in models:
            model = models[modelname]
            has_populate = 'populate_scripts' in model and len(model['populate_scripts']) > 0

            if has_populate:
                print(f"  [OK] {modelname} ({tablename}) - Has populate script")
            else:
                print(f"  [WARNING] {modelname} ({tablename}) - NO POPULATE SCRIPT")
                all_good = False
        else:
            print(f"  [ERROR] {modelname} - MODEL NOT FOUND")
            all_good = False

    if all_good:
        print("\n[SUCCESS] All critical models have populate scripts!")
    else:
        print("\n[WARNING] Some critical models may need populate scripts!")

    # Final summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"Total models defined: {len(models)}")
    print(f"Core models: {len(core_models)}")
    print(f"Phase 1 models: {len(phase1_models)}")
    print(f"Total foreign keys: {fk_count}")
    print(f"Active populate scripts: {len([k for k,v in operations.items() if v['models_used'] or v['queries']])}")

    print("\n" + "=" * 80)


if __name__ == '__main__':
    check_model_sync()
