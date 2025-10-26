"""
Analyze Derik's role competency vectors to see if they have high similarity too
"""
import re

def parse_derik_data():
    """Parse Derik's role_competency_matrix from init.sql"""
    with open("C:\\Users\\jomon\\Documents\\MyDocuments\\Development\\Thesis\\sesurveyapp-main\\postgres-init\\init.sql", "r", encoding="utf-8") as f:
        content = f.read()

    # Find the COPY section for role_competency_matrix
    pattern = r"COPY public\.role_competency_matrix.*?FROM stdin;(.*?)\\\."
    match = re.search(pattern, content, re.DOTALL)

    if not match:
        print("ERROR: Could not find role_competency_matrix data in init.sql")
        return {}

    lines = match.group(1).strip().split('\n')
    print(f"Found {len(lines)} total entries in Derik's init.sql")

    # Parse the data
    data = {}  # {role_id: {competency_id: value}}
    for line in lines:
        if line.strip():
            parts = line.split('\t')
            if len(parts) >= 5:
                # Format: id, role_cluster_id, competency_id, role_competency_value, organization_id
                role_id = int(parts[1])
                comp_id = int(parts[2])
                value = int(parts[3])
                org_id = int(parts[4])

                if org_id == 1:
                    if role_id not in data:
                        data[role_id] = {}
                    data[role_id][comp_id] = value

    return data

def main():
    print("="*80)
    print("ANALYZING DERIK'S ROLE COMPETENCY VECTORS")
    print("="*80)

    data = parse_derik_data()

    if not data:
        return

    print(f"\nParsed data for {len(data)} roles")

    # Get role names (hardcode from Derik's system)
    role_names = {
        1: "Customer",
        2: "Customer Representative",
        3: "Project Manager",
        4: "System Engineer",
        5: "Specialist Developer",
        6: "Production Planner/Coordinator",
        7: "Production Employee",
        8: "Quality Engineer/Manager",
        9: "Verification and Validation (V&V) Operator",
        10: "Service Technician",
        11: "Process and Policy Manager",
        12: "Internal Support",
        13: "Innovation Management",
        14: "Management"
    }

    # Show each role's vector
    print("\n" + "="*80)
    print("COMPETENCY VECTORS BY ROLE (Derik's Data)")
    print("="*80)

    for role_id in sorted(data.keys()):
        vector = data[role_id]
        role_name = role_names.get(role_id, f"Unknown Role {role_id}")

        print(f"\nRole {role_id} - {role_name}")
        print(f"  Entries: {len(vector)}")

        # Value distribution
        value_counts = {}
        for comp_id, value in vector.items():
            value_counts[value] = value_counts.get(value, 0) + 1

        print(f"  Value distribution: {dict(sorted(value_counts.items()))}")

        # Show actual vector
        sorted_comps = sorted(vector.keys())
        vec_str = ", ".join([str(vector[c]) for c in sorted_comps])
        print(f"  Competencies: {sorted_comps}")
        print(f"  Vector: [{vec_str}]")

    # Calculate similarity between roles
    print("\n" + "="*80)
    print("ROLE SIMILARITY ANALYSIS (Derik's Data)")
    print("="*80)

    # Convert to lists for comparison (using only common competencies)
    all_comps = set()
    for role_id in data:
        all_comps.update(data[role_id].keys())

    sorted_all_comps = sorted(all_comps)
    print(f"\nAll competencies in Derik's data: {sorted_all_comps}")

    vectors = {}
    for role_id in data:
        # Build vector with all competencies (use -100 for missing)
        vectors[role_id] = [data[role_id].get(c, -100) for c in sorted_all_comps]

    # Compare each pair of roles
    print("\nComparing role pairs (number of matching competency values):")
    print(f"{'Role 1':<30} {'Role 2':<30} {'Matches':<10} {'Total':<10} {'Similarity %':<15}")
    print("-"*95)

    similarities = []
    for i, role1_id in enumerate(sorted(data.keys())):
        for role2_id in sorted(data.keys())[i+1:]:
            vec1 = vectors[role1_id]
            vec2 = vectors[role2_id]

            # Count matching values (excluding -100)
            matches = sum(1 for v1, v2 in zip(vec1, vec2) if v1 == v2 and v1 != -100)
            total = sum(1 for v1, v2 in zip(vec1, vec2) if v1 != -100 and v2 != -100)
            similarity = (matches / total * 100) if total > 0 else 0

            role1_name = role_names.get(role1_id, f"Role {role1_id}")
            role2_name = role_names.get(role2_id, f"Role {role2_id}")

            similarities.append((role1_name, role2_name, matches, total, similarity))

    # Sort by similarity (highest first) and show high similarities
    similarities.sort(key=lambda x: x[4], reverse=True)

    for role1_name, role2_name, matches, total, similarity in similarities:
        if similarity > 50:  # Only show >50% similar
            print(f"{role1_name[:29]:<30} {role2_name[:29]:<30} {matches:<10} {total:<10} {similarity:>6.2f}%")

    print("\n" + "="*80)
    print("ANALYSIS COMPLETE")
    print("="*80)

if __name__ == "__main__":
    main()
