"""
Fetch role descriptions from database and update the frontend seRoleClusters.js file
"""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app
from models import db, RoleCluster

# Mapping between database role names and frontend role IDs
ROLE_MAPPING = {
    "Customer": 1,
    "Customer Representative": 2,
    "Project Manager": 3,
    "System Engineer": 4,
    "Specialist Developer": 5,
    "Production Planner/Coordinator": 6,
    "Production Employee": 7,
    "Quality Engineer/Manager": 8,
    "Verification and Validation (V&V) Operator": 9,
    "Service Technician": 10,
    "Process and Policy Manager": 11,
    "Internal Support": 12,
    "Innovation Management": 13,
    "Management": 14
}

# Frontend categories for each role
ROLE_CATEGORIES = {
    1: "Customer",
    2: "Customer",
    3: "Management",
    4: "Development",
    5: "Development",
    6: "Production",
    7: "Production",
    8: "Quality",
    9: "Quality",
    10: "Service",
    11: "Management",
    12: "Support",
    13: "Management",
    14: "Management"
}

def fetch_descriptions():
    """Fetch all role descriptions from the database"""
    app = create_app()
    with app.app_context():
        roles = RoleCluster.query.all()

        role_data = {}
        for role in roles:
            if role.role_cluster_name in ROLE_MAPPING:
                role_id = ROLE_MAPPING[role.role_cluster_name]
                role_data[role_id] = {
                    'id': role_id,
                    'name': role.role_cluster_name,
                    'description': role.role_cluster_description,
                    'category': ROLE_CATEGORIES[role_id]
                }

        return role_data


def generate_js_file(role_data):
    """Generate the seRoleClusters.js file content"""

    js_content = """/**
 * Standard SE Role Clusters (14 roles)
 * Based on SE4OWL research project
 * Used in Phase 1 Task 2: Identify SE Roles
 *
 * NOTE: This file is auto-generated from the database.
 * To update descriptions, modify the database and run: update_frontend_role_descriptions.py
 */

export const SE_ROLE_CLUSTERS = [
"""

    # Generate each role entry
    for role_id in sorted(role_data.keys()):
        role = role_data[role_id]
        # Escape quotes and newlines in description
        desc = role['description'].replace('\\', '\\\\').replace('"', '\\"').replace('\n', ' ')

        js_content += f"""  {{
    id: {role['id']},
    name: "{role['name']}",
    description: "{desc}",
    category: "{role['category']}"
  }},
"""

    # Remove trailing comma and close array
    js_content = js_content.rstrip(',\n') + '\n'
    js_content += """];

/**
 * Target group size categories with implications
 */
export const TARGET_GROUP_SIZES = [
  {
    id: 'small',
    range: '< 20',
    category: 'SMALL',
    label: 'Less than 20 people',
    description: 'Small group - suitable for intensive workshops',
    value: 10,
    implications: {
      formats: ['Workshop', 'Coaching', 'Mentoring'],
      approach: 'Direct intensive training',
      trainTheTrainer: false
    }
  },
  {
    id: 'medium',
    range: '20-100',
    category: 'MEDIUM',
    label: '20 - 100 people',
    description: 'Medium group - mixed format approach recommended',
    value: 60,
    implications: {
      formats: ['Workshop', 'Blended Learning', 'Group Projects'],
      approach: 'Mixed format with cohorts',
      trainTheTrainer: false
    }
  },
  {
    id: 'large',
    range: '100-500',
    category: 'LARGE',
    label: '100 - 500 people',
    description: 'Large group - consider train-the-trainer approach',
    value: 300,
    implications: {
      formats: ['Blended Learning', 'E-Learning', 'Train-the-Trainer'],
      approach: 'Scalable formats required',
      trainTheTrainer: true
    }
  },
  {
    id: 'xlarge',
    range: '500-1500',
    category: 'VERY_LARGE',
    label: '500 - 1500 people',
    description: 'Very large group - phased rollout recommended',
    value: 1000,
    implications: {
      formats: ['E-Learning', 'Train-the-Trainer', 'Self-paced'],
      approach: 'Phased rollout with trainers',
      trainTheTrainer: true
    }
  },
  {
    id: 'xxlarge',
    range: '> 1500',
    category: 'ENTERPRISE',
    label: 'More than 1500 people',
    description: 'Enterprise scale - comprehensive program required',
    value: 2000,
    implications: {
      formats: ['E-Learning Platform', 'Train-the-Trainer', 'Learning Management System'],
      approach: 'Enterprise learning program',
      trainTheTrainer: true
    }
  }
];
"""

    return js_content


def main():
    print("\n=== Updating Frontend Role Descriptions ===\n")

    # Fetch descriptions from database
    print("Fetching role descriptions from database...")
    role_data = fetch_descriptions()

    print(f"Found {len(role_data)} roles\n")

    # Generate JavaScript content
    print("Generating JavaScript file...")
    js_content = generate_js_file(role_data)

    # Write to file
    frontend_file = r'C:\Users\jomon\Documents\MyDocuments\Development\Thesis\SE-QPT-Master-Thesis\src\frontend\src\data\seRoleClusters.js'

    try:
        with open(frontend_file, 'w', encoding='utf-8') as f:
            f.write(js_content)
        print(f"\n[OK] Updated: {frontend_file}\n")

        # Show sample
        print("Sample of updated descriptions:")
        for role_id in [1, 4, 8, 14]:  # Show a few examples
            if role_id in role_data:
                role = role_data[role_id]
                print(f"\n{role['name']}:")
                print(f"  {role['description'][:100]}...")

    except Exception as e:
        print(f"\n[ERROR] Failed to write file: {e}")
        import traceback
        traceback.print_exc()


if __name__ == '__main__':
    main()
