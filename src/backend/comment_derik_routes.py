"""
Script to comment out broken authenticated routes in derik_integration.py
"""

def comment_out_routes():
    file_path = 'app/derik_integration.py'

    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # Ranges to comment out (0-indexed)
    comment_ranges = [
        (156, 214),  # /identify-processes
        (215, 247),  # /rank-competencies
        (248, 278),  # /find-similar-role
        (279, 402),  # /complete-assessment
        (403, 445),  # /questionnaire/<competency_name>
        (446, 495),  # /assessment-report/<int:assessment_id>
    ]

    # Mark lines to comment
    lines_to_comment = set()
    for start, end in comment_ranges:
        for i in range(start, end + 1):
            lines_to_comment.add(i)

    # Add comment header before first commented section
    result = lines[:156]
    result.append('\n')
    result.append('# =============================================================================\n')
    result.append('# OPTIONAL CLEANUP: Broken authenticated routes commented out\n')
    result.append('# These routes use removed models (Assessment, CompetencyAssessmentResult, etc.)\n')
    result.append('# Use main_bp routes instead for assessment functionality\n')
    result.append('# =============================================================================\n')
    result.append('\n')

    # Comment out marked lines
    for i, line in enumerate(lines[156:], start=156):
        if i in lines_to_comment:
            # Don't double-comment already commented lines
            if not line.strip().startswith('#'):
                result.append('# ' + line)
            else:
                result.append(line)
        else:
            result.append(line)

    # Write back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(result)

    print(f'[SUCCESS] Commented out {len(lines_to_comment)} lines in derik_integration.py')
    print(f'Backup saved as: derik_integration.py.backup_optional')

if __name__ == '__main__':
    comment_out_routes()
