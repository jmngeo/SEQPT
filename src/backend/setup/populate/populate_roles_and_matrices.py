"""
Populate role_cluster and role_process_matrix tables with Derik's data
This implements the proper role-to-process mapping system
"""

import os
os.environ['DATABASE_URL'] = 'postgresql://seqpt_admin:SeQpt_2025@localhost:5432/seqpt_database'

from app import create_app
from models import db, RoleCluster, RoleProcessMatrix

app = create_app()

with app.app_context():
    print("=" * 80)
    print("POPULATING ROLES AND ROLE-PROCESS MATRICES")
    print("=" * 80)

    # First, populate role_cluster table
    roles_data = [
        (1, "Customer", "Represents the party that orders or uses a service (e.g., development order). The customer has influence on the design/technical execution of the system."),
        (2, "Customer Representative", "Forms the interface between the customer and the company. The roles in this cluster form the voice for all customer-relevant information required for the project."),
        (3, "Project Manager", "Is responsible for the planning and coordination on the project side. The roles assume responsibility for achieving the project goals and monitoring the resources (time, costs, personnel) within a time-limited framework and also have a moderating role in conflicts and disputes."),
        (4, "System Engineer", "Has the overview from requirements to the decomposition of the system to the interfaces and the associated system elements (external to the system environment and internal between the elements). The system developer is responsible for integration planning and consults with the appropriate subject matter experts."),
        (5, "Specialist Developer", "Includes the various specialist areas, e.g., software, hardware, etc. They develop new technologies or realize the product/system on the basis of specifications from the system developer cluster."),
        (6, "Production Planner/Coordinator", "Takes on the preparation of the product realization and the transfer to the customer."),
        (7, "Production Employee", "Comprises the processes that are to be assigned to the implementation, assembly, and manufacture of the product through to goods issue and shipping. The individual system components are integrated into the overall system and verified with regard to their functionality."),
        (8, "Quality Engineer/Manager", "Ensures that the company's quality standards are maintained in order to keep customer satisfaction high and ensure long-term competitiveness in the market. Close cooperation with the V&V operator, e.g., for the analysis of customer complaints and identification of the cause."),
        (9, "Verification and Validation (V&V) Operator", "Covers the topics of system verification & validation. The involvement of this role cluster in the early phases of system development can ensure that the system is verifiable and validatable."),
        (10, "Service Technician", "Deals with all service-related tasks at the customer's site, i.e., installation, commissioning, professional training of users, as well as classic service tasks such as maintenance and repairs, or the area of after-sales."),
        (11, "Process and Policy Manager", "Is divided into a strategic and an operational level: On a strategic level, the process owner serves to develop internal guidelines in the development and creation or revision of process flows. On an operational level, the policy owner controls compliance with policies, laws, and framework conditions that must be taken into account and fulfilled."),
        (12, "Internal Support", "Represents the advisory and supporting side during the development process within the project. A distinction is made between: - IT support: IT support provides and maintains the necessary IT infrastructure. - Qualification support: On the one hand, this provides support in the area of methods and, on the other hand, the qualification of the employees is individually ensured by means of specialized training. This can be done by the HR department, which also supports the project by acquiring suitable employees. - Systems Engineering (SE) support: The SE support offers separate support with regard to SE methods and handling of SE tools. This offers assistance in order to impart the necessary knowledge in the SE procedure."),
        (13, "Innovation Management", "Focuses on the commercially successful implementation of products or services, but also new business models or processes."),
        (14, "Management", "Forms the group of decision-makers and is represented by the management or department management. The cluster keeps an eye on the company's goals, visions, and values. Since the opinion of the cluster is crucial for project progress, management is an important stakeholder in every respect."),
    ]

    print("\n[1/3] Populating role_cluster table...")
    for role_id, role_name, description in roles_data:
        # Check if role already exists
        existing_role = RoleCluster.query.filter_by(id=role_id).first()
        if existing_role:
            print(f"  Role {role_id} already exists, skipping...")
            continue

        role = RoleCluster(
            id=role_id,
            role_cluster_name=role_name,
            role_cluster_description=description
        )
        db.session.add(role)
        print(f"  Added: {role_id}. {role_name}")

    db.session.commit()
    print(f"[OK] {len(roles_data)} roles populated")

    # Now populate role_process_matrix
    # Format: (role_cluster_id, iso_process_id, role_process_value)
    # Values: 0=Not performing, 1=Supporting, 2=Responsible, 4=Designing
    print("\n[2/3] Populating role_process_matrix table...")

    # COMPLETE role-process matrix data from Derik's system (organization_id=1)
    # NOTE: We have 30 ISO processes (1-30) based on ISO 15288:2015
    # Source: sesurveyapp/postgres-init/init.sql

    # All 14 roles with their complete process mappings
    # Format: (role_cluster_id, iso_process_id, role_process_value)
    # Values: 0=Not performing, 1=Supporting, 2=Responsible, 3=Designing (Process and Policy Manager), 4=Designing

    all_mappings = [
        # Role 1: Customer
        (1, 1, 0), (1, 2, 0), (1, 3, 0), (1, 4, 0), (1, 5, 0), (1, 6, 0), (1, 7, 0),
        (1, 8, 0), (1, 9, 0), (1, 10, 0), (1, 11, 0), (1, 12, 0), (1, 13, 0), (1, 14, 0),
        (1, 15, 0), (1, 16, 0), (1, 17, 0), (1, 18, 0), (1, 19, 0), (1, 20, 0), (1, 21, 0),
        (1, 22, 0), (1, 23, 0), (1, 24, 0), (1, 25, 0), (1, 26, 2), (1, 27, 1), (1, 28, 2),
        (1, 29, 2), (1, 30, 2),

        # Role 2: Customer Representative
        (2, 1, 0), (2, 2, 2), (2, 3, 0), (2, 4, 0), (2, 5, 1), (2, 6, 0), (2, 7, 0),
        (2, 8, 0), (2, 9, 0), (2, 10, 0), (2, 11, 2), (2, 12, 1), (2, 13, 1), (2, 14, 1),
        (2, 15, 0), (2, 16, 1), (2, 17, 2), (2, 18, 2), (2, 19, 2), (2, 20, 1), (2, 21, 1),
        (2, 22, 0), (2, 23, 0), (2, 24, 1), (2, 25, 1), (2, 26, 2), (2, 27, 1), (2, 28, 0),
        (2, 29, 0), (2, 30, 0),

        # Role 3: Project Manager
        (3, 1, 0), (3, 2, 1), (3, 3, 0), (3, 4, 0), (3, 5, 1), (3, 6, 0), (3, 7, 0),
        (3, 8, 0), (3, 9, 2), (3, 10, 2), (3, 11, 2), (3, 12, 2), (3, 13, 2), (3, 14, 2),
        (3, 15, 0), (3, 16, 1), (3, 17, 0), (3, 18, 0), (3, 19, 0), (3, 20, 0), (3, 21, 0),
        (3, 22, 0), (3, 23, 0), (3, 24, 0), (3, 25, 0), (3, 26, 0), (3, 27, 0), (3, 28, 0),
        (3, 29, 0), (3, 30, 0),

        # Role 4: System Engineer
        (4, 1, 1), (4, 2, 1), (4, 3, 0), (4, 4, 0), (4, 5, 0), (4, 6, 0), (4, 7, 0),
        (4, 8, 0), (4, 9, 0), (4, 10, 0), (4, 11, 2), (4, 12, 2), (4, 13, 2), (4, 14, 1),
        (4, 15, 0), (4, 16, 0), (4, 17, 0), (4, 18, 1), (4, 19, 2), (4, 20, 2), (4, 21, 2),
        (4, 22, 1), (4, 23, 0), (4, 24, 0), (4, 25, 1), (4, 26, 0), (4, 27, 0), (4, 28, 1),
        (4, 29, 1), (4, 30, 0),

        # Role 5: Specialist Developer
        (5, 1, 1), (5, 2, 0), (5, 3, 0), (5, 4, 0), (5, 5, 0), (5, 6, 0), (5, 7, 0),
        (5, 8, 0), (5, 9, 0), (5, 10, 0), (5, 11, 1), (5, 12, 1), (5, 13, 1), (5, 14, 1),
        (5, 15, 1), (5, 16, 0), (5, 17, 0), (5, 18, 0), (5, 19, 1), (5, 20, 1), (5, 21, 2),
        (5, 22, 0), (5, 23, 2), (5, 24, 0), (5, 25, 1), (5, 26, 0), (5, 27, 0), (5, 28, 0),
        (5, 29, 0), (5, 30, 0),

        # Role 6: Production Planner/Coordinator
        (6, 1, 2), (6, 2, 1), (6, 3, 0), (6, 4, 0), (6, 5, 0), (6, 6, 0), (6, 7, 0),
        (6, 8, 0), (6, 9, 0), (6, 10, 0), (6, 11, 1), (6, 12, 1), (6, 13, 0), (6, 14, 0),
        (6, 15, 0), (6, 16, 0), (6, 17, 0), (6, 18, 0), (6, 19, 0), (6, 20, 0), (6, 21, 0),
        (6, 22, 0), (6, 23, 2), (6, 24, 1), (6, 25, 0), (6, 26, 2), (6, 27, 0), (6, 28, 0),
        (6, 29, 0), (6, 30, 0),

        # Role 7: Production Employee
        (7, 1, 0), (7, 2, 0), (7, 3, 0), (7, 4, 0), (7, 5, 0), (7, 6, 0), (7, 7, 0),
        (7, 8, 0), (7, 9, 0), (7, 10, 0), (7, 11, 0), (7, 12, 0), (7, 13, 0), (7, 14, 0),
        (7, 15, 0), (7, 16, 0), (7, 17, 0), (7, 18, 0), (7, 19, 0), (7, 20, 0), (7, 21, 0),
        (7, 22, 0), (7, 23, 2), (7, 24, 2), (7, 25, 0), (7, 26, 0), (7, 27, 0), (7, 28, 0),
        (7, 29, 0), (7, 30, 0),

        # Role 8: Quality Engineer/Manager
        (8, 1, 0), (8, 2, 0), (8, 3, 0), (8, 4, 0), (8, 5, 0), (8, 6, 0), (8, 7, 2),
        (8, 8, 0), (8, 9, 0), (8, 10, 0), (8, 11, 0), (8, 12, 1), (8, 13, 0), (8, 14, 0),
        (8, 15, 0), (8, 16, 2), (8, 17, 0), (8, 18, 0), (8, 19, 0), (8, 20, 0), (8, 21, 0),
        (8, 22, 0), (8, 23, 0), (8, 24, 0), (8, 25, 1), (8, 26, 0), (8, 27, 1), (8, 28, 0),
        (8, 29, 0), (8, 30, 0),

        # Role 9: Verification and Validation (V&V) Operator
        (9, 1, 1), (9, 2, 0), (9, 3, 0), (9, 4, 0), (9, 5, 0), (9, 6, 0), (9, 7, 1),
        (9, 8, 0), (9, 9, 0), (9, 10, 0), (9, 11, 1), (9, 12, 0), (9, 13, 1), (9, 14, 1),
        (9, 15, 2), (9, 16, 2), (9, 17, 0), (9, 18, 1), (9, 19, 1), (9, 20, 0), (9, 21, 0),
        (9, 22, 2), (9, 23, 0), (9, 24, 1), (9, 25, 2), (9, 26, 0), (9, 27, 2), (9, 28, 0),
        (9, 29, 0), (9, 30, 0),

        # Role 10: Service Technician
        (10, 1, 0), (10, 2, 1), (10, 3, 0), (10, 4, 0), (10, 5, 0), (10, 6, 0), (10, 7, 0),
        (10, 8, 0), (10, 9, 0), (10, 10, 0), (10, 11, 0), (10, 12, 0), (10, 13, 0), (10, 14, 0),
        (10, 15, 0), (10, 16, 0), (10, 17, 0), (10, 18, 0), (10, 19, 0), (10, 20, 0), (10, 21, 0),
        (10, 22, 0), (10, 23, 0), (10, 24, 0), (10, 25, 0), (10, 26, 2), (10, 27, 0), (10, 28, 1),
        (10, 29, 2), (10, 30, 1),

        # Role 11: Process and Policy Manager
        (11, 1, 3), (11, 2, 3), (11, 3, 3), (11, 4, 3), (11, 5, 3), (11, 6, 3), (11, 7, 3),
        (11, 8, 3), (11, 9, 3), (11, 10, 3), (11, 11, 3), (11, 12, 3), (11, 13, 3), (11, 14, 3),
        (11, 15, 3), (11, 16, 3), (11, 17, 3), (11, 18, 3), (11, 19, 3), (11, 20, 3), (11, 21, 3),
        (11, 22, 3), (11, 23, 3), (11, 24, 3), (11, 25, 3), (11, 26, 3), (11, 27, 3), (11, 28, 3),
        (11, 29, 3), (11, 30, 3),

        # Role 12: Internal Support
        (12, 1, 0), (12, 2, 0), (12, 3, 1), (12, 4, 2), (12, 5, 0), (12, 6, 2), (12, 7, 0),
        (12, 8, 2), (12, 9, 0), (12, 10, 0), (12, 11, 0), (12, 12, 0), (12, 13, 0), (12, 14, 0),
        (12, 15, 0), (12, 16, 0), (12, 17, 0), (12, 18, 0), (12, 19, 0), (12, 20, 0), (12, 21, 0),
        (12, 22, 0), (12, 23, 0), (12, 24, 0), (12, 25, 0), (12, 26, 0), (12, 27, 0), (12, 28, 0),
        (12, 29, 0), (12, 30, 0),

        # Role 13: Innovation Management
        (13, 1, 0), (13, 2, 0), (13, 3, 0), (13, 4, 0), (13, 5, 2), (13, 6, 0), (13, 7, 0),
        (13, 8, 0), (13, 9, 0), (13, 10, 0), (13, 11, 1), (13, 12, 0), (13, 13, 0), (13, 14, 0),
        (13, 15, 0), (13, 16, 0), (13, 17, 2), (13, 18, 0), (13, 19, 0), (13, 20, 0), (13, 21, 0),
        (13, 22, 0), (13, 23, 0), (13, 24, 0), (13, 25, 0), (13, 26, 0), (13, 27, 0), (13, 28, 0),
        (13, 29, 0), (13, 30, 0),

        # Role 14: Management
        (14, 1, 0), (14, 2, 0), (14, 3, 0), (14, 4, 0), (14, 5, 1), (14, 6, 1), (14, 7, 0),
        (14, 8, 0), (14, 9, 0), (14, 10, 1), (14, 11, 2), (14, 12, 0), (14, 13, 0), (14, 14, 0),
        (14, 15, 0), (14, 16, 0), (14, 17, 1), (14, 18, 0), (14, 19, 0), (14, 20, 0), (14, 21, 0),
        (14, 22, 0), (14, 23, 0), (14, 24, 0), (14, 25, 0), (14, 26, 0), (14, 27, 0), (14, 28, 0),
        (14, 29, 0), (14, 30, 0),
    ]

    for role_id, process_id, value in all_mappings:
        # Check if mapping already exists
        existing = RoleProcessMatrix.query.filter_by(
            role_cluster_id=role_id,
            iso_process_id=process_id,
            organization_id=1
        ).first()

        if existing:
            continue

        mapping = RoleProcessMatrix(
            role_cluster_id=role_id,
            iso_process_id=process_id,
            role_process_value=value,
            organization_id=1  # Default organization
        )
        db.session.add(mapping)

    db.session.commit()
    print(f"[OK] {len(all_mappings)} role-process mappings added")

    # Verify the data
    print("\n[3/3] Verifying populated data...")
    total_roles = RoleCluster.query.count()
    total_mappings = RoleProcessMatrix.query.count()

    print(f"  Total roles in database: {total_roles}")
    print(f"  Total role-process mappings: {total_mappings}")

    # Show System Engineer mappings as example
    se_role = RoleCluster.query.filter_by(role_cluster_name="System Engineer").first()
    if se_role:
        se_mappings = RoleProcessMatrix.query.filter_by(role_cluster_id=se_role.id).all()
        responsible_processes = [m for m in se_mappings if m.role_process_value == 2]
        designing_processes = [m for m in se_mappings if m.role_process_value == 4]
        print(f"\n  System Engineer role:")
        print(f"    - Responsible for {len(responsible_processes)} processes")
        print(f"    - Designing {len(designing_processes)} processes")

    print("\n" + "=" * 80)
    print("POPULATION COMPLETE")
    print("=" * 80)
