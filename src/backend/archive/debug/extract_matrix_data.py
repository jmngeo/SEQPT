"""
Extract complete role-process matrix data from Derik's init.sql
"""

import re

# Read the init.sql file
with open(r'C:\Users\jomon\Documents\MyDocuments\Development\Thesis\sesurveyapp-main\postgres-init\init.sql', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the role_process_matrix COPY section
# Format: COPY public.role_process_matrix ... FROM stdin;
# ... data ...
# \.

# Find the start
start_pos = content.find('COPY public.role_process_matrix')
if start_pos == -1:
    print("Could not find role_process_matrix COPY statement")
    exit(1)

# Find FROM stdin after the COPY statement
from_stdin_pos = content.find('FROM stdin;', start_pos)
if from_stdin_pos == -1:
    print("Could not find FROM stdin")
    exit(1)

# Data starts after the newline
data_start = from_stdin_pos + len('FROM stdin;\n')

# Find the end marker \. (backslash-dot on its own line)
data_end = content.find('\n\\.', data_start)
if data_end == -1:
    # Try with just \.
    data_end = content.find('\.', data_start)

if data_end != -1:
    data_section = content[data_start:data_end]
    lines = data_section.strip().split('\n')

    # Parse the data: id, role_cluster_id, iso_process_id, role_process_value, organization_id
    role_data = {}

    for line in lines:
        parts = line.strip().split('\t')
        if len(parts) == 5:
            id_val, role_id, process_id, value, org_id = map(int, parts)

            # Only keep org_id=1 and process_id <= 28
            if org_id == 1 and process_id <= 28:
                if role_id not in role_data:
                    role_data[role_id] = []
                role_data[role_id].append((role_id, process_id, value))

    # Print the data organized by role
    print("ALL ROLE-PROCESS MATRIX DATA (organization_id=1, processes 1-28)")
    print("=" * 80)

    for role_id in sorted(role_data.keys()):
        print(f"\nRole {role_id}:")
        entries = role_data[role_id]
        print(f"    role_{role_id}_mappings = [")
        for role, process, value in entries:
            print(f"        ({role}, {process}, {value}),")
        print(f"    ]")
        print(f"    # Total: {len(entries)} process mappings")

    # Summary
    print("\n" + "=" * 80)
    print("SUMMARY:")
    for role_id in sorted(role_data.keys()):
        print(f"  Role {role_id}: {len(role_data[role_id])} mappings")
    print(f"\nTotal roles: {len(role_data)}")
    print(f"Total mappings: {sum(len(v) for v in role_data.values())}")
else:
    print("Could not find role_process_matrix data in init.sql")
