"""
Update role descriptions with brief summaries instead of long descriptions
"""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app
from models import db, RoleCluster

# Brief descriptions for all 14 roles (concise, 1-2 sentences)
BRIEF_DESCRIPTIONS = {
    "Customer": "Party that orders or uses the service/product with influence on system design.",

    "Customer Representative": "Interface between customer and company, voice for customer requirements.",

    "Project Manager": "Responsible for project planning, coordination, and achieving goals within constraints.",

    "System Engineer": "Oversees requirements, system decomposition, interfaces, and integration planning.",

    "Specialist Developer": "Develops in specific areas (software, hardware, etc.) based on system specifications.",

    "Production Planner/Coordinator": "Prepares product realization and transfer to customer.",

    "Production Employee": "Handles implementation, assembly, manufacture, and product integration.",

    "Quality Engineer/Manager": "Ensures quality standards are maintained and cooperates with V&V.",

    "Verification and Validation (V&V) Operator": "Performs system verification and validation activities.",

    "Service Technician": "Handles installation, commissioning, training, maintenance, and repair.",

    "Process and Policy Manager": "Develops internal guidelines and monitors process compliance.",

    "Internal Support": "Provides advisory and support during development (IT, qualification, SE support).",

    "Innovation Management": "Focuses on commercial implementation of products/services and new business models.",

    "Management": "Decision-makers providing company vision, goals, and project oversight."
}


def update_database_descriptions():
    """Update the database with brief descriptions"""
    print("\n=== Updating Database with Brief Descriptions ===\n")

    app = create_app()
    with app.app_context():
        updated_count = 0

        for role_name, brief_desc in BRIEF_DESCRIPTIONS.items():
            role = RoleCluster.query.filter_by(role_cluster_name=role_name).first()

            if role:
                old_desc = role.role_cluster_description
                role.role_cluster_description = brief_desc
                updated_count += 1

                print(f"[OK] {role_name}")
                print(f"     Old: {old_desc[:60]}...")
                print(f"     New: {brief_desc}\n")
            else:
                print(f"[WARNING] Role not found: {role_name}\n")

        # Commit changes
        try:
            db.session.commit()
            print(f"\n=== Summary ===")
            print(f"Updated {updated_count} roles with brief descriptions")
            print(f"Changes committed successfully!\n")
        except Exception as e:
            db.session.rollback()
            print(f"\nERROR: {e}")
            import traceback
            traceback.print_exc()


def update_frontend_file():
    """Update the frontend seRoleClusters.js file"""
    print("\n=== Updating Frontend File ===\n")

    # Role ID mapping
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

    # Role categories
    ROLE_CATEGORIES = {
        1: "Customer", 2: "Customer", 3: "Management", 4: "Development",
        5: "Development", 6: "Production", 7: "Production", 8: "Quality",
        9: "Quality", 10: "Service", 11: "Management", 12: "Support",
        13: "Management", 14: "Management"
    }

    # Generate JavaScript content
    js_content = """/**
 * Standard SE Role Clusters (14 roles)
 * Based on SE4OWL research project
 * Used in Phase 1 Task 2: Identify SE Roles
 *
 * NOTE: Descriptions are brief summaries for UI display
 */

export const SE_ROLE_CLUSTERS = [
"""

    for role_name, role_id in sorted(ROLE_MAPPING.items(), key=lambda x: x[1]):
        brief_desc = BRIEF_DESCRIPTIONS[role_name].replace('\\', '\\\\').replace('"', '\\"')
        category = ROLE_CATEGORIES[role_id]

        js_content += f"""  {{
    id: {role_id},
    name: "{role_name}",
    description: "{brief_desc}",
    category: "{category}"
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

    # Write to file
    frontend_file = r'C:\Users\jomon\Documents\MyDocuments\Development\Thesis\SE-QPT-Master-Thesis\src\frontend\src\data\seRoleClusters.js'

    try:
        with open(frontend_file, 'w', encoding='utf-8') as f:
            f.write(js_content)
        print(f"[OK] Updated: {frontend_file}\n")

        # Show samples
        print("Sample brief descriptions:")
        for role_name in ["Customer", "System Engineer", "Quality Engineer/Manager", "Management"]:
            print(f"\n{role_name}:")
            print(f"  {BRIEF_DESCRIPTIONS[role_name]}")

    except Exception as e:
        print(f"\nERROR: Failed to write file: {e}")
        import traceback
        traceback.print_exc()


if __name__ == '__main__':
    import sys

    # Check for auto-confirm flag
    auto_confirm = len(sys.argv) > 1 and sys.argv[1] == '--yes'

    print("\n" + "="*70)
    print("This will update role descriptions to BRIEF summaries")
    print("="*70)

    if auto_confirm:
        print("\nAuto-confirming (--yes flag provided)\n")
        update_database_descriptions()
        update_frontend_file()
    else:
        response = input("\nProceed? (yes/no): ").strip().lower()
        if response in ['yes', 'y']:
            update_database_descriptions()
            update_frontend_file()
        else:
            print("\nCancelled by user.")
