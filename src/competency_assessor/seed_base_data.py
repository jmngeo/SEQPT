"""
Seed script to populate foundational data from Derik's original implementation
This includes: Competencies, Role Clusters, and ISO Processes
"""

from app import create_app, db
from app.models import Competency, RoleCluster, IsoProcesses
from sqlalchemy import text

def seed_competencies():
    """Seed competency data"""
    print("Seeding competencies...")

    competencies_data = [
        (1, "Core", "Systems Thinking", "The application of the fundamental concepts of systems thinking to Systems Engineering...", "Systems thinking is a way of dealing with increasing complexity..."),
        (4, "Core", "Lifecycle Consideration", "", ""),
        (5, "Core", "Customer / Value Orientation", "", ""),
        (6, "Core", "Systems Modeling and Analysis", "", ""),
        (7, "Social / Personal", "Communication", "", ""),
        (8, "Social / Personal", "Leadership", "", ""),
        (9, "Social / Personal", "Self-Organization", "", ""),
        (10, "Management", "Project Management", "", ""),
        (11, "Management", "Decision Management", "", ""),
        (12, "Management", "Information Management", "", ""),
        (13, "Management", "Configuration Management", "", ""),
        (14, "Technical", "Requirements Definition", "", ""),
        (15, "Technical", "System Architecting", "", ""),
        (16, "Technical", "Integration, Verification, Validation", "", ""),
        (17, "Technical", "Operation and Support", "", ""),
        (18, "Technical", "Agile Methods", "", ""),
    ]

    for id, area, name, desc, why in competencies_data:
        existing = Competency.query.filter_by(id=id).first()
        if not existing:
            comp = Competency(
                id=id,
                competency_area=area,
                competency_name=name,
                description=desc,
                why_it_matters=why
            )
            db.session.add(comp)

    db.session.commit()
    print(f"[OK] Seeded {len(competencies_data)} competencies")


def seed_role_clusters():
    """Seed role cluster data"""
    print("Seeding role clusters...")

    roles_data = [
        (1, "Customer", "Represents the party that orders or uses a service"),
        (2, "Customer Representative", "Forms the interface between the customer and the company"),
        (3, "Project Manager", "Is responsible for the planning and coordination on the project side"),
        (4, "System Engineer", "Has the overview from requirements to the decomposition of the system"),
        (5, "Specialist Developer", "Includes the various specialist areas, e.g., software, hardware, etc."),
        (6, "Production Planner/Coordinator", "Takes on the preparation of the product realization"),
        (7, "Production Employee", "Comprises the processes assigned to implementation and assembly"),
        (8, "Quality Engineer/Manager", "Ensures that the company's quality standards are maintained"),
        (9, "Verification and Validation (V&V) Operator", "Covers system verification & validation"),
        (10, "Service Technician", "Deals with all service-related tasks at the customer's site"),
        (11, "Process and Policy Manager", "Divided into strategic and operational level"),
        (12, "Internal Support", "Represents the advisory and supporting side during development"),
        (13, "Innovation Management", "Focuses on commercially successful implementation of products"),
        (14, "Management", "Forms the group of decision-makers"),
    ]

    for id, name, desc in roles_data:
        existing = RoleCluster.query.filter_by(id=id).first()
        if not existing:
            role = RoleCluster(
                id=id,
                role_cluster_name=name,
                role_cluster_description=desc
            )
            db.session.add(role)

    db.session.commit()
    print(f"[OK] Seeded {len(roles_data)} role clusters")


def seed_iso_processes():
    """Seed ISO process data"""
    print("Seeding ISO processes...")

    processes_data = [
        (1, "Acquisition process", "Used by organizations for acquiring products or services"),
        (2, "Supply process", "Used by organizations for supplying products or services"),
        (3, "Life cycle model management process", "Define, maintain, and help ensure availability of policies"),
        (4, "Infrastructure management process", "Provide infrastructure and services to projects"),
        (5, "Portfolio management process", "Initiate and sustain necessary projects"),
        (6, "Human resource management process", "Provide necessary human resources"),
        (7, "Quality management process", "Assure products meet quality objectives"),
        (8, "Knowledge management process", "Create capability to exploit opportunities"),
        (9, "Project planning process", "Produce and coordinate effective plans"),
        (10, "Project assessment and control process", "Assess if plans are aligned and feasible"),
        (11, "Decision management process", "Provide structured analytical framework"),
        (12, "Risk management process", "Identify, analyse, treat, and monitor risks"),
        (13, "Configuration management process", "Manage system configurations"),
        (14, "Information management process", "Generate, obtain, and manage information"),
        (15, "Measurement process", "Collect and analyse objective data"),
        (16, "Quality assurance process", "Help ensure effective quality management"),
        (17, "Business or mission analysis process", "Define strategic problem or opportunity"),
        (18, "Stakeholder needs and requirements definition process", "Define stakeholder needs"),
        (19, "System requirements definition process", "Transform stakeholder view into technical view"),
        (20, "System architecture definition process", "Generate system architecture alternatives"),
        (21, "Design definition process", "Provide detailed system data and information"),
        (22, "System analysis process", "Provide rigorous basis for technical understanding"),
        (23, "Implementation process", "Realise a specified system element"),
        (24, "Integration process", "Synthesize system elements into realised system"),
        (25, "Verification process", "Provide objective evidence of requirements fulfillment"),
        (26, "Transition process", "Establish capability to provide services"),
        (27, "Validation process", "Provide evidence of business/mission objectives fulfillment"),
        (28, "Operation process", "Use the system to provide products or services"),
        (29, "Maintenance process", "Sustain capability to provide product or service"),
        (30, "Disposal process", "End the existence of a system element"),
    ]

    for id, name, desc in processes_data:
        existing = IsoProcesses.query.filter_by(id=id).first()
        if not existing:
            process = IsoProcesses(
                id=id,
                name=name,
                description=desc
            )
            db.session.add(process)

    db.session.commit()
    print(f"[OK] Seeded {len(processes_data)} ISO processes")


def main():
    """Main seed function"""
    print("=" * 60)
    print("Starting database seeding with Derik's foundational data...")
    print("=" * 60)

    app = create_app()
    with app.app_context():
        try:
            seed_competencies()
            seed_role_clusters()
            seed_iso_processes()

            print("=" * 60)
            print("[SUCCESS] Database seeding completed successfully!")
            print("=" * 60)
            print("\nYou can now use the matrix CRUD pages:")
            print("  - Role-Process Matrix: /admin/matrix/role-process")
            print("  - Process-Competency Matrix: /admin/matrix/process-competency")

        except Exception as e:
            print(f"\n[ERROR] Error during seeding: {e}")
            db.session.rollback()
            raise


if __name__ == '__main__':
    main()
