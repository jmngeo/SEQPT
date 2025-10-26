"""
Process-based role matching (simpler and more accurate than competency-based)
Directly compares user's process involvement to role-process matrix
"""
import numpy as np
from sqlalchemy import func
from models import db, RoleProcessMatrix


def find_role_by_process_match(organization_id, user_process_data):
    """
    Find best matching role based on direct process involvement comparison.

    Args:
        organization_id: int
        user_process_data: list of dicts with {'iso_process_id': int, 'involvement': int}
            where involvement: 0=Not performing, 1=Supporting, 2=Responsible, 3/4=Designing

    Returns:
        dict with role_ids, similarity_score, and details
    """
    # Query all role-process matrices for this organization
    results = (
        db.session.query(
            RoleProcessMatrix.role_cluster_id,
            RoleProcessMatrix.iso_process_id,
            RoleProcessMatrix.role_process_value
        )
        .filter(RoleProcessMatrix.organization_id == organization_id)
        .order_by(RoleProcessMatrix.role_cluster_id, RoleProcessMatrix.iso_process_id)
        .all()
    )

    # Organize by role
    role_processes = {}
    all_process_ids = set()

    for role_id, process_id, value in results:
        if role_id not in role_processes:
            role_processes[role_id] = {}
        role_processes[role_id][process_id] = value
        all_process_ids.add(process_id)

    # Create user process vector
    user_process_map = {p['iso_process_id']: p['involvement'] for p in user_process_data}

    # Get all process IDs (1-28 typically)
    all_process_ids = sorted(all_process_ids)

    # Build vectors
    user_vector = np.array([user_process_map.get(pid, 0) for pid in all_process_ids])

    role_vectors = {}
    for role_id, processes in role_processes.items():
        role_vectors[role_id] = np.array([processes.get(pid, 0) for pid in all_process_ids])

    # Calculate similarities using multiple metrics
    similarities = {}

    for role_id, role_vector in role_vectors.items():
        # Euclidean distance (lower is better)
        euclidean = np.linalg.norm(user_vector - role_vector)

        # Manhattan distance (lower is better)
        manhattan = np.sum(np.abs(user_vector - role_vector))

        # Cosine similarity (higher is better, so we use 1 - distance)
        dot_product = np.dot(user_vector, role_vector)
        magnitude_user = np.linalg.norm(user_vector)
        magnitude_role = np.linalg.norm(role_vector)

        if magnitude_user > 0 and magnitude_role > 0:
            cosine_similarity = dot_product / (magnitude_user * magnitude_role)
            cosine_distance = 1 - cosine_similarity
        else:
            cosine_distance = 1.0

        # Overlap score: how many processes match exactly
        exact_matches = np.sum(user_vector == role_vector)
        overlap_score = exact_matches / len(all_process_ids)

        # Process coverage: how many of user's processes are covered by this role
        user_active = user_vector > 0
        role_covers_user = np.sum((user_vector > 0) & (role_vector > 0))
        coverage_score = role_covers_user / max(np.sum(user_active), 1)

        similarities[role_id] = {
            'euclidean': euclidean,
            'manhattan': manhattan,
            'cosine': cosine_distance,
            'overlap': overlap_score,
            'coverage': coverage_score,
            'vector': role_vector
        }

    # Determine best match (primary: euclidean, secondary: coverage)
    best_role_id = min(similarities.keys(), key=lambda rid: (
        similarities[rid]['euclidean'],
        -similarities[rid]['coverage']  # Negative because higher is better
    ))

    # Count metric agreement
    euclidean_best = min(similarities.keys(), key=lambda rid: similarities[rid]['euclidean'])
    manhattan_best = min(similarities.keys(), key=lambda rid: similarities[rid]['manhattan'])
    cosine_best = min(similarities.keys(), key=lambda rid: similarities[rid]['cosine'])

    metric_agreement = sum([
        best_role_id == euclidean_best,
        best_role_id == manhattan_best,
        best_role_id == cosine_best
    ])

    # Calculate confidence based on distance and agreement
    min_distance = similarities[best_role_id]['euclidean']
    coverage = similarities[best_role_id]['coverage']

    # Distance-based confidence (28-dimensional process vectors, values 0-4)
    # Typical distances: 0-10 excellent, 10-20 good, 20-30 fair, 30+ poor
    if min_distance < 5:
        base_confidence = 0.95
    elif min_distance < 10:
        base_confidence = 0.90
    elif min_distance < 15:
        base_confidence = 0.85
    elif min_distance < 20:
        base_confidence = 0.75
    elif min_distance < 25:
        base_confidence = 0.65
    else:
        base_confidence = 0.55

    # Boost confidence if coverage is high
    if coverage > 0.8:
        base_confidence = min(base_confidence + 0.05, 0.99)

    # Adjust for metric agreement
    if metric_agreement == 3:
        confidence = min(base_confidence + 0.05, 0.99)
    elif metric_agreement == 2:
        confidence = base_confidence
    else:
        confidence = max(base_confidence - 0.05, 0.50)

    print(f"[process_match] Best role: {best_role_id}")
    print(f"[process_match] Distance: {min_distance:.2f}, Coverage: {coverage:.1%}, Agreement: {metric_agreement}/3")
    print(f"[process_match] Confidence: {confidence*100:.0f}%")

    return {
        'role_ids': [best_role_id],
        'similarity_score': confidence,
        'min_distance': min_distance,
        'coverage': coverage,
        'metric_agreement': metric_agreement,
        'similarities': similarities
    }
