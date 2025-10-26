"""
Script to replace complex role suggestion function with simple version
"""

# Read the main routes file
with open('src/backend/app/routes.py', 'r', encoding='utf-8') as f:
    routes_content = f.read()

# Read the simplified function
with open('src/backend/app/routes_role_suggestion_SIMPLE.py', 'r', encoding='utf-8') as f:
    simple_func = f.read()

# Remove the decorators/imports from simple_func file (keep only the function)
simple_func_lines = simple_func.split('\n')
# Skip first 6 lines (comments + blank line)
simple_func_clean = '\n'.join(simple_func_lines[6:])

# Find the start and end of the function to replace
start_marker = "@main_bp.route('/api/phase1/roles/suggest-from-processes', methods=['POST'])"
end_marker = "\n\n@main_bp.route('/api/phase1/target-group/<int:org_id>', methods=['GET'])"

start_idx = routes_content.find(start_marker)
end_idx = routes_content.find(end_marker)

if start_idx == -1 or end_idx == -1:
    print("ERROR: Could not find function markers")
    print(f"Start found: {start_idx != -1}")
    print(f"End found: {end_idx != -1}")
    exit(1)

print(f"Found function at position {start_idx} to {end_idx}")
print(f"Function size: {end_idx - start_idx} characters")

# Replace the function
new_routes = (
    routes_content[:start_idx] +
    simple_func_clean +
    routes_content[end_idx:]
)

# Write back
with open('src/backend/app/routes.py', 'w', encoding='utf-8') as f:
    f.write(new_routes)

print("✓ Successfully replaced function!")
print(f"  Old size: {len(routes_content)} bytes")
print(f"  New size: {len(new_routes)} bytes")
print(f"  Reduction: {len(routes_content) - len(new_routes)} bytes")
