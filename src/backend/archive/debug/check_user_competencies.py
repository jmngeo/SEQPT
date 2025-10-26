#!/usr/bin/env python3
"""
Check competency values for a specific user
"""
import os
import sys
import psycopg2
from psycopg2 import sql

# Database connection
DATABASE_URL = "postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment"

def check_user_competencies(username):
    """Check competency requirements for a user"""
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()

    print(f"\n=== Competency Values for User: {username} ===\n")

    # Check process involvement
    cur.execute("""
        SELECT
            ip.name as process_name,
            urpm.role_process_value
        FROM unknown_role_process_matrix urpm
        JOIN iso_processes ip ON urpm.iso_process_id = ip.id
        WHERE urpm.user_name = %s
        AND urpm.role_process_value != 0
        ORDER BY urpm.role_process_value DESC, ip.name;
    """, (username,))

    process_rows = cur.fetchall()

    if process_rows:
        print(f"Process Involvement ({len(process_rows)} non-zero):")
        for process_name, value in process_rows:
            involvement = {4: 'Designing', 2: 'Responsible', 1: 'Supporting'}.get(value, 'Unknown')
            print(f"  {process_name}: {value} ({involvement})")
    else:
        print("No process involvement data found")

    print()

    # Check competency requirements
    cur.execute("""
        SELECT
            c.competency_name,
            urcm.role_competency_value
        FROM unknown_role_competency_matrix urcm
        JOIN competency c ON urcm.competency_id = c.id
        WHERE urcm.user_name = %s
        AND urcm.role_competency_value != 0
        ORDER BY urcm.role_competency_value DESC, c.competency_name;
    """, (username,))

    competency_rows = cur.fetchall()

    if competency_rows:
        print(f"Competency Requirements ({len(competency_rows)} non-zero):")
        for comp_name, value in competency_rows:
            print(f"  {comp_name}: {value}")
    else:
        print("No competency requirements found")

    # Compare with Specialist Developer role
    print("\n=== Comparison with Specialist Developer (Role ID 2) ===\n")

    cur.execute("""
        SELECT
            c.competency_name,
            rcm.role_competency_value as role_value,
            COALESCE(urcm.role_competency_value, 0) as user_value,
            ABS(rcm.role_competency_value - COALESCE(urcm.role_competency_value, 0)) as diff
        FROM role_competency_matrix rcm
        JOIN competency c ON rcm.competency_id = c.id
        LEFT JOIN unknown_role_competency_matrix urcm ON urcm.competency_id = rcm.competency_id
            AND urcm.user_name = %s
        WHERE rcm.role_cluster_id = 2
        AND rcm.organization_id = 11
        ORDER BY diff DESC
        LIMIT 20;
    """, (username,))

    comparison_rows = cur.fetchall()

    print("Top 20 Competency Differences:")
    total_diff = 0
    for comp_name, role_val, user_val, diff in comparison_rows:
        print(f"  {comp_name}: Role={role_val}, User={user_val}, Diff={diff}")
        total_diff += diff ** 2

    euclidean_distance = (total_diff ** 0.5)
    print(f"\nEuclidean Distance to Specialist Developer: {euclidean_distance:.4f}")

    # Also check Project Manager
    print("\n=== Comparison with Project Manager (Role ID 3) ===\n")

    cur.execute("""
        SELECT
            c.competency_name,
            rcm.role_competency_value as role_value,
            COALESCE(urcm.role_competency_value, 0) as user_value,
            ABS(rcm.role_competency_value - COALESCE(urcm.role_competency_value, 0)) as diff
        FROM role_competency_matrix rcm
        JOIN competency c ON rcm.competency_id = c.id
        LEFT JOIN unknown_role_competency_matrix urcm ON urcm.competency_id = rcm.competency_id
            AND urcm.user_name = %s
        WHERE rcm.role_cluster_id = 3
        AND rcm.organization_id = 11
        ORDER BY diff DESC
        LIMIT 20;
    """, (username,))

    comparison_rows = cur.fetchall()

    print("Top 20 Competency Differences:")
    total_diff = 0
    for comp_name, role_val, user_val, diff in comparison_rows:
        print(f"  {comp_name}: Role={role_val}, User={user_val}, Diff={diff}")
        total_diff += diff ** 2

    euclidean_distance = (total_diff ** 0.5)
    print(f"\nEuclidean Distance to Project Manager: {euclidean_distance:.4f}")

    cur.close()
    conn.close()

if __name__ == '__main__':
    if len(sys.argv) > 1:
        username = sys.argv[1]
    else:
        username = "phase1_temp_1761076421752_dbnyodnuc"  # Default from the frontend log

    check_user_competencies(username)
